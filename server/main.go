package main

import (
	"fmt"
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/greenbamboo/server/internal/database"
	"github.com/greenbamboo/server/internal/handlers"
)

func main() {
	// 初始化数据库
	db, err := database.InitDB()
	if err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}

	// 自动迁移数据库表
	err = database.AutoMigrate(db)
	if err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}

	// 设置 Gin 模式
	mode := os.Getenv("GIN_MODE")
	if mode == "" {
		mode = gin.ReleaseMode
	}
	gin.SetMode(mode)

	// 创建 Gin 路由
	r := gin.Default()

	// 健康检查
	r.GET("/api/v1/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status": "ok",
			"message": "GreenBamboo server is running",
		})
	})

	// 将数据库注入到上下文
	r.Use(func(c *gin.Context) {
		c.Set("db", db)
		c.Next()
	})

	// API v1 路由组
	v1 := r.Group("/api/v1")
	{
		// 认证路由（公开）
		auth := v1.Group("/auth")
		{
			auth.POST("/register", handlers.Register)
			auth.POST("/login", handlers.Login)
		}

		// 需要认证的路由
		authorized := v1.Group("")
		authorized.Use(handlers.JWTAuthMiddleware())
		{
			// 用户
			authorized.GET("/user/profile", handlers.GetProfile)
			authorized.PUT("/user/profile", handlers.UpdateProfile)

			// 指标
			authorized.GET("/metrics", handlers.GetMetrics)
			authorized.POST("/metrics", handlers.CreateMetric)
			authorized.PUT("/metrics/:id", handlers.UpdateMetric)
			authorized.DELETE("/metrics/:id", handlers.DeleteMetric)

			// 记录
			authorized.GET("/records", handlers.GetRecords)
			authorized.POST("/records", handlers.CreateRecord)
			authorized.POST("/records/bulk", handlers.CreateRecordsBulk)
			authorized.PUT("/records/:id", handlers.UpdateRecord)
			authorized.DELETE("/records/:id", handlers.DeleteRecord)

			// 统计
			authorized.GET("/stats/trend", handlers.GetTrendStats)
			authorized.GET("/stats/summary", handlers.GetSummaryStats)

			// 同步
			authorized.POST("/sync", handlers.Sync)
		}
	}

	// 获取端口
	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	// 启动服务器
	fmt.Printf("🎋 GreenBamboo server starting on port %s\n", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
