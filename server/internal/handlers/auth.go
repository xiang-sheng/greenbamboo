package handlers

import (
	"crypto/rand"
	"encoding/hex"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"

	"github.com/greenbamboo/server/internal/database"
)

// RegisterRequest 注册请求
type RegisterRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
}

// LoginRequest 登录请求
type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

// AuthResponse 认证响应
type AuthResponse struct {
	Token     string `json:"token"`
	ExpiresIn int64  `json:"expires_in"` // 秒
	User      UserVO `json:"user"`
}

// UserVO 用户视图对象
type UserVO struct {
	ID    string `json:"id"`
	Email string `json:"email"`
}

// Register 用户注册
func Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    40000,
			"message": err.Error(),
		})
		return
	}

	db := c.MustGet("db").(*gorm.DB)

	// 检查邮箱是否已存在
	var existingUser database.User
	if err := db.Where("email = ?", req.Email).First(&existingUser).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{
			"code":    40900,
			"message": "Email already registered",
		})
		return
	}

	// 加密密码
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    50000,
			"message": "Failed to hash password",
		})
		return
	}

	// 创建用户
	user := database.User{
		ID:           generateID(),
		Email:        req.Email,
		PasswordHash: string(hashedPassword),
	}

	if err := db.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    50000,
			"message": "Failed to create user",
		})
		return
	}

	// 创建预置指标
	presets := database.GetPresetMetrics()
	for _, p := range presets {
		preset := p
		preset.ID = generateID()
		preset.UserID = user.ID
		if err := db.Create(&preset).Error; err != nil {
			log.Printf("Failed to create preset metric %s: %v", preset.Name, err)
		}
	}

	// 生成 JWT Token
	token, err := generateToken(user.ID, user.Email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    50000,
			"message": "Failed to generate token",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data": AuthResponse{
			Token:     token,
			ExpiresIn: 7 * 24 * 3600, // 7 天
			User: UserVO{
				ID:    user.ID,
				Email: user.Email,
			},
		},
	})
}

// Login 用户登录
func Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    40000,
			"message": err.Error(),
		})
		return
	}

	db := c.MustGet("db").(*gorm.DB)

	// 查找用户
	var user database.User
	if err := db.Where("email = ?", req.Email).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"code":    40100,
			"message": "Invalid email or password",
		})
		return
	}

	// 验证密码
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"code":    40100,
			"message": "Invalid email or password",
		})
		return
	}

	// 生成 JWT Token
	token, err := generateToken(user.ID, user.Email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    50000,
			"message": "Failed to generate token",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data": AuthResponse{
			Token:     token,
			ExpiresIn: 7 * 24 * 3600, // 7 天
			User: UserVO{
				ID:    user.ID,
				Email: user.Email,
			},
		},
	})
}

// GetProfile 获取用户信息
func GetProfile(c *gin.Context) {
	userID := c.GetString("userID")
	userEmail := c.GetString("userEmail")

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data": UserVO{
			ID:    userID,
			Email: userEmail,
		},
	})
}

// UpdateProfile 更新用户信息
func UpdateProfile(c *gin.Context) {
	c.JSON(http.StatusNotImplemented, gin.H{
		"code":    50100,
		"message": "Profile update not yet implemented",
	})
}

// JWTAuthMiddleware JWT 认证中间件
func JWTAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code":    40100,
				"message": "Missing authorization header",
			})
			c.Abort()
			return
		}

		// 提取 Token
		if len(authHeader) < 7 || authHeader[:7] != "Bearer " {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code":    40100,
				"message": "Invalid authorization header",
			})
			c.Abort()
			return
		}
		tokenString := authHeader[7:]

		// 解析 Token
		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, jwt.ErrSignatureInvalid
			}
			return []byte(getJWTSecret()), nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code":    40100,
				"message": "Invalid token",
			})
			c.Abort()
			return
		}

		// 提取 Claims
		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code":    40100,
				"message": "Invalid token claims",
			})
			c.Abort()
			return
		}

		userID, ok := claims["user_id"].(string)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"code": 40100, "message": "Invalid token claims: missing user_id"})
			c.Abort()
			return
		}
		userEmail, ok := claims["email"].(string)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"code": 40100, "message": "Invalid token claims: missing email"})
			c.Abort()
			return
		}

		c.Set("userID", userID)
		c.Set("userEmail", userEmail)
		c.Next()
	}
}

// generateToken 生成 JWT Token
func generateToken(userID, email string) (string, error) {
	secret := getJWTSecret()
	expireTime := time.Now().Add(7 * 24 * time.Hour)

	claims := jwt.MapClaims{
		"user_id": userID,
		"email":   email,
		"exp":     expireTime.Unix(),
		"iat":     time.Now().Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

// getJWTSecret 获取 JWT 密钥
func getJWTSecret() string {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		log.Println("WARNING: JWT_SECRET not set, using auto-generated random secret")
		b := make([]byte, 32)
		if _, err := rand.Read(b); err != nil {
			log.Printf("Failed to generate random JWT secret: %v", err)
			return "greenbamboo-fallback-secret-DO-NOT-use-in-production"
		}
		secret = hex.EncodeToString(b)
	}
	return secret
}

// generateID 生成 ID
func generateID() string {
	return time.Now().Format("20060102150405") + "_" + generateRandomString(8)
}

// generateRandomString 生成随机字符串
func generateRandomString(n int) string {
	b := make([]byte, n)
	if _, err := rand.Read(b); err != nil {
		log.Printf("Failed to generate random string: %v", err)
		return hex.EncodeToString([]byte(time.Now().Format("20060102150405")))[:n]
	}
	return hex.EncodeToString(b)[:n]
}
