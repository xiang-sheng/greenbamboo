package handlers

import (
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
		db.Create(&preset)
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
	// TODO: 实现更新逻辑
	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
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
		tokenString := authHeader[7:] // 去掉 "Bearer "
		if len(authHeader) < 7 || authHeader[:7] != "Bearer " {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code":    40100,
				"message": "Invalid authorization header",
			})
			c.Abort()
			return
		}

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

		userID := claims["user_id"].(string)
		userEmail := claims["email"].(string)

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
		secret = "greenbamboo-default-secret-change-in-production"
	}
	return secret
}

// generateID 生成 ID
func generateID() string {
	return time.Now().Format("20060102150405") + "_" + generateRandomString(8)
}

// generateRandomString 生成随机字符串
func generateRandomString(n int) string {
	const letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	b := make([]byte, n)
	for i := range b {
		b[i] = letters[time.Now().UnixNano()%int64(len(letters))]
		time.Sleep(time.Nanosecond) // 确保随机性
	}
	return string(b)
}
