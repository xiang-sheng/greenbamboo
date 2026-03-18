package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"github.com/greenbamboo/server/internal/database"
)

// SyncRequest 同步请求
type SyncRequest struct {
	LastSync      int64                 `json:"last_sync"` // 上次同步时间戳
	LocalChanges  []CreateRecordRequest `json:"local_changes"`
	DeviceID      string                `json:"device_id"`
	DeviceName    string                `json:"device_name"`
	AppVersion    string                `json:"app_version"`
}

// SyncResponse 同步响应
type SyncResponse struct {
	ServerChanges []RecordVO `json:"server_changes"`
	Conflicts     []Conflict `json:"conflicts"`
	NewLastSync   int64      `json:"new_last_sync"`
}

// Conflict 冲突记录
type Conflict struct {
	Local  RecordVO `json:"local"`
	Server RecordVO `json:"server"`
}

// Sync 数据同步
func Sync(c *gin.Context) {
	userID := c.GetString("userID")
	var req SyncRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    40000,
			"message": err.Error(),
		})
		return
	}

	db := c.MustGet("db").(*gorm.DB)

	// 1. 上传本地更改
	uploadedIDs := make([]string, 0)
	for _, localRecord := range req.LocalChanges {
		// 验证指标
		var metric database.Metric
		if err := db.Where("id = ? AND user_id = ?", localRecord.MetricID, userID).First(&metric).Error; err != nil {
			continue // 跳过无效记录
		}

		record := database.HealthRecord{
			ID:         generateID(),
			UserID:     userID,
			MetricID:   localRecord.MetricID,
			Value:      localRecord.Value,
			TextValue:  localRecord.TextValue,
			Note:       localRecord.Note,
			RecordedAt: localRecord.RecordedAt,
		}
		if record.RecordedAt == 0 {
			record.RecordedAt = time.Now().Unix()
		}

		if err := db.Create(&record).Error; err == nil {
			uploadedIDs = append(uploadedIDs, record.ID)
		}
	}

	// 2. 下载服务器更改
	var serverRecords []database.HealthRecord
	query := db.Where("user_id = ? AND created_at > ?", userID, req.LastSync)
	if err := query.Order("created_at ASC").Find(&serverRecords).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    50000,
			"message": "Failed to get server changes",
		})
		return
	}

	// 转换为 VO
	serverChanges := make([]RecordVO, 0, len(serverRecords))
	for _, r := range serverRecords {
		vo := RecordVO{
			ID:         r.ID,
			MetricID:   r.MetricID,
			Value:      r.Value,
			TextValue:  r.TextValue,
			Note:       r.Note,
			RecordedAt: r.RecordedAt,
			CreatedAt:  r.CreatedAt,
		}

		// 获取指标名称
		var metric database.Metric
		if err := db.Where("id = ?", r.MetricID).First(&metric).Error; err == nil {
			vo.MetricName = metric.Name
		}

		serverChanges = append(serverChanges, vo)
	}

	// 3. 更新设备信息
	if req.DeviceID != "" {
		device := database.Device{
			ID:         req.DeviceID,
			UserID:     userID,
			DeviceName: req.DeviceName,
			LastSync:   time.Now().Unix(),
		}
		db.Where("id = ? AND user_id = ?", req.DeviceID, userID).FirstOrCreate(&device)
	}

	// 4. 返回同步结果
	newLastSync := time.Now().Unix()

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data": SyncResponse{
			ServerChanges: serverChanges,
			Conflicts:     []Conflict{}, // TODO: 实现冲突检测
			NewLastSync:   newLastSync,
		},
	})
}
