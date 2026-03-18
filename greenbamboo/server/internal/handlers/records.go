package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"github.com/greenbamboo/server/internal/database"
)

// RecordVO 记录视图对象
type RecordVO struct {
	ID         string  `json:"id"`
	MetricID   string  `json:"metric_id"`
	MetricName string  `json:"metric_name,omitempty"`
	Value      float64 `json:"value"`
	TextValue  string  `json:"text_value,omitempty"`
	Note       string  `json:"note"`
	RecordedAt int64   `json:"recorded_at"`
	CreatedAt  int64   `json:"created_at"`
}

// CreateRecordRequest 创建记录请求
type CreateRecordRequest struct {
	MetricID   string  `json:"metric_id" binding:"required"`
	Value      float64 `json:"value"`
	TextValue  string  `json:"text_value"`
	Note       string  `json:"note"`
	RecordedAt int64   `json:"recorded_at"` // 时间戳，秒
}

// CreateRecordsBulkRequest 批量创建记录请求
type CreateRecordsBulkRequest struct {
	Records []CreateRecordRequest `json:"records" binding:"required,min=1,dive"`
}

// GetRecords 获取记录列表
func GetRecords(c *gin.Context) {
	userID := c.GetString("userID")
	db := c.MustGet("db").(*gorm.DB)

	// 查询参数
	metricID := c.Query("metric_id")
	since := c.Query("since")
	limitStr := c.Query("limit")

	limit := 100
	if limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 && l <= 500 {
			limit = l
		}
	}

	query := db.Where("user_id = ?", userID)

	// 按指标筛选
	if metricID != "" {
		query = query.Where("metric_id = ?", metricID)
	}

	// 按时间筛选
	if since != "" {
		if t, err := time.Parse(time.RFC3339, since); err == nil {
			query = query.Where("recorded_at > ?", t.Unix())
		}
	}

	var records []database.HealthRecord
	if err := query.Order("recorded_at DESC").Limit(limit).Find(&records).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    50000,
			"message": "Failed to get records",
		})
		return
	}

	// 转换为 VO（包含指标名称）
	recordVOs := make([]RecordVO, 0, len(records))
	for _, r := range records {
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

		recordVOs = append(recordVOs, vo)
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data":    recordVOs,
	})
}

// CreateRecord 创建记录
func CreateRecord(c *gin.Context) {
	userID := c.GetString("userID")
	var req CreateRecordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    40000,
			"message": err.Error(),
		})
		return
	}

	db := c.MustGet("db").(*gorm.DB)

	// 验证指标是否存在
	var metric database.Metric
	if err := db.Where("id = ? AND user_id = ?", req.MetricID, userID).First(&metric).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    40400,
			"message": "Metric not found",
		})
		return
	}

	record := database.HealthRecord{
		ID:         generateID(),
		UserID:     userID,
		MetricID:   req.MetricID,
		Value:      req.Value,
		TextValue:  req.TextValue,
		Note:       req.Note,
		RecordedAt: req.RecordedAt,
	}

	if record.RecordedAt == 0 {
		record.RecordedAt = time.Now().Unix()
	}

	if err := db.Create(&record).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    50000,
			"message": "Failed to create record",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data": RecordVO{
			ID:         record.ID,
			MetricID:   record.MetricID,
			MetricName: metric.Name,
			Value:      record.Value,
			TextValue:  record.TextValue,
			Note:       record.Note,
			RecordedAt: record.RecordedAt,
			CreatedAt:  record.CreatedAt,
		},
	})
}

// CreateRecordsBulk 批量创建记录
func CreateRecordsBulk(c *gin.Context) {
	userID := c.GetString("userID")
	var req CreateRecordsBulkRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    40000,
			"message": err.Error(),
		})
		return
	}

	db := c.MustGet("db").(*gorm.DB)

	// 验证所有指标
	metricMap := make(map[string]database.Metric)
	for _, r := range req.Records {
		if _, exists := metricMap[r.MetricID]; !exists {
			var metric database.Metric
			if err := db.Where("id = ? AND user_id = ?", r.MetricID, userID).First(&metric).Error; err != nil {
				c.JSON(http.StatusNotFound, gin.H{
					"code":    40400,
					"message": "Metric not found: " + r.MetricID,
				})
				return
			}
			metricMap[r.MetricID] = metric
		}
	}

	// 批量创建
	records := make([]database.HealthRecord, 0, len(req.Records))
	for _, r := range req.Records {
		record := database.HealthRecord{
			ID:         generateID(),
			UserID:     userID,
			MetricID:   r.MetricID,
			Value:      r.Value,
			TextValue:  r.TextValue,
			Note:       r.Note,
			RecordedAt: r.RecordedAt,
		}
		if record.RecordedAt == 0 {
			record.RecordedAt = time.Now().Unix()
		}
		records = append(records, record)
	}

	if err := db.Create(&records).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    50000,
			"message": "Failed to create records",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data": gin.H{
			"created": len(records),
		},
	})
}

// UpdateRecord 更新记录
func UpdateRecord(c *gin.Context) {
	userID := c.GetString("userID")
	recordID := c.Param("id")

	db := c.MustGet("db").(*gorm.DB)

	var record database.HealthRecord
	if err := db.Where("id = ? AND user_id = ?", recordID, userID).First(&record).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{
				"code":    40400,
				"message": "Record not found",
			})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    50000,
			"message": "Failed to get record",
		})
		return
	}

	var req CreateRecordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    40000,
			"message": err.Error(),
		})
		return
	}

	record.MetricID = req.MetricID
	record.Value = req.Value
	record.TextValue = req.TextValue
	record.Note = req.Note
	if req.RecordedAt != 0 {
		record.RecordedAt = req.RecordedAt
	}

	if err := db.Save(&record).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    50000,
			"message": "Failed to update record",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data": RecordVO{
			ID:         record.ID,
			MetricID:   record.MetricID,
			Value:      record.Value,
			TextValue:  record.TextValue,
			Note:       record.Note,
			RecordedAt: record.RecordedAt,
			CreatedAt:  record.CreatedAt,
		},
	})
}

// DeleteRecord 删除记录
func DeleteRecord(c *gin.Context) {
	userID := c.GetString("userID")
	recordID := c.Param("id")

	db := c.MustGet("db").(*gorm.DB)

	if err := db.Where("id = ? AND user_id = ?", recordID, userID).Delete(&database.HealthRecord{}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    50000,
			"message": "Failed to delete record",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
	})
}
