package database

import (
	"os"
	"path/filepath"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// InitDB 初始化数据库连接
func InitDB() (*gorm.DB, error) {
	// 获取数据库路径
	dbPath := os.Getenv("DB_PATH")
	if dbPath == "" {
		dbPath = "./data/health.db"
	}

	// 确保目录存在
	dir := filepath.Dir(dbPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return nil, err
	}

	// 打开数据库连接
	db, err := gorm.Open(sqlite.Open(dbPath), &gorm.Config{})
	if err != nil {
		return nil, err
	}

	return db, nil
}

// AutoMigrate 自动迁移数据库表
func AutoMigrate(db *gorm.DB) error {
	return db.AutoMigrate(
		&User{},
		&Metric{},
		&HealthRecord{},
		&Device{},
	)
}

// User 用户模型
type User struct {
	ID           string `gorm:"primaryKey;type:text"`
	Email        string `gorm:"uniqueIndex;type:text;not null"`
	PasswordHash string `gorm:"type:text;not null"`
	CreatedAt    int64  `gorm:"autoCreateTime"`
	UpdatedAt    int64  `gorm:"autoUpdateTime"`
}

// Metric 健康指标模型
type Metric struct {
	ID        string `gorm:"primaryKey;type:text"`
	UserID    string `gorm:"index;type:text;not null"`
	Name      string `gorm:"type:text;not null"`
	Type      string `gorm:"type:text;not null"` // number, boolean, select
	Unit      string `gorm:"type:text"`
	IsPreset  bool   `gorm:"default:false"`
	CreatedAt int64  `gorm:"autoCreateTime"`
	UpdatedAt int64  `gorm:"autoUpdateTime"`
}

// HealthRecord 健康记录模型
type HealthRecord struct {
	ID          string  `gorm:"primaryKey;type:text"`
	UserID      string  `gorm:"index;type:text;not null"`
	MetricID    string  `gorm:"index;type:text;not null"`
	Value       float64 `gorm:"type:real"`
	TextValue   string  `gorm:"type:text"`
	Note        string  `gorm:"type:text"`
	RecordedAt  int64   `gorm:"index;not null"` // 记录时间（时间戳）
	CreatedAt   int64   `gorm:"autoCreateTime"`
	UpdatedAt   int64   `gorm:"autoUpdateTime"`
}

// Device 设备模型（用于多设备同步）
type Device struct {
	ID         string `gorm:"primaryKey;type:text"`
	UserID     string `gorm:"index;type:text;not null"`
	DeviceName string `gorm:"type:text"`
	LastSync   int64  `gorm:"index"`
	CreatedAt  int64  `gorm:"autoCreateTime"`
	UpdatedAt  int64  `gorm:"autoUpdateTime"`
}
