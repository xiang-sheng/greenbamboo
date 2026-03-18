package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"github.com/greenbamboo/server/internal/database"
)

// MetricVO 指标视图对象
type MetricVO struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	Type      string `json:"type"`
	Unit      string `json:"unit"`
	IsPreset  bool   `json:"is_preset"`
	CreatedAt int64  `json:"created_at"`
}

// CreateMetricRequest 创建指标请求
type CreateMetricRequest struct {
	Name string `json:"name" binding:"required"`
	Type string `json:"type" binding:"required,oneof=number boolean select"`
	Unit string `json:"unit"`
}

// GetMetrics 获取指标列表
func GetMetrics(c *gin.Context) {
	userID := c.GetString("userID")
	db := c.MustGet("db").(*gorm.DB)

	var metrics []database.Metric
	if err := db.Where("user_id = ?", userID).Order("created_at DESC").Find(&metrics).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    50000,
			"message": "Failed to get metrics",
		})
		return
	}

	// 转换为 VO
	metricVOs := make([]MetricVO, 0, len(metrics))
	for _, m := range metrics {
		metricVOs = append(metricVOs, MetricVO{
			ID:        m.ID,
			Name:      m.Name,
			Type:      m.Type,
			Unit:      m.Unit,
			IsPreset:  m.IsPreset,
			CreatedAt: m.CreatedAt,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data":    metricVOs,
	})
}

// CreateMetric 创建指标
func CreateMetric(c *gin.Context) {
	userID := c.GetString("userID")
	var req CreateMetricRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    40000,
			"message": err.Error(),
		})
		return
	}

	db := c.MustGet("db").(*gorm.DB)

	metric := database.Metric{
		ID:       generateID(),
		UserID:   userID,
		Name:     req.Name,
		Type:     req.Type,
		Unit:     req.Unit,
		IsPreset: false,
	}

	if err := db.Create(&metric).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    50000,
			"message": "Failed to create metric",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data": MetricVO{
			ID:        metric.ID,
			Name:      metric.Name,
			Type:      metric.Type,
			Unit:      metric.Unit,
			IsPreset:  metric.IsPreset,
			CreatedAt: metric.CreatedAt,
		},
	})
}

// UpdateMetric 更新指标
func UpdateMetric(c *gin.Context) {
	userID := c.GetString("userID")
	metricID := c.Param("id")

	db := c.MustGet("db").(*gorm.DB)

	var metric database.Metric
	if err := db.Where("id = ? AND user_id = ?", metricID, userID).First(&metric).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{
				"code":    40400,
				"message": "Metric not found",
			})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    50000,
			"message": "Failed to get metric",
		})
		return
	}

	var req CreateMetricRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    40000,
			"message": err.Error(),
		})
		return
	}

	metric.Name = req.Name
	metric.Type = req.Type
	metric.Unit = req.Unit

	if err := db.Save(&metric).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    50000,
			"message": "Failed to update metric",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data": MetricVO{
			ID:        metric.ID,
			Name:      metric.Name,
			Type:      metric.Type,
			Unit:      metric.Unit,
			IsPreset:  metric.IsPreset,
			CreatedAt: metric.CreatedAt,
		},
	})
}

// DeleteMetric 删除指标
func DeleteMetric(c *gin.Context) {
	userID := c.GetString("userID")
	metricID := c.Param("id")

	db := c.MustGet("db").(*gorm.DB)

	if err := db.Where("id = ? AND user_id = ?", metricID, userID).Delete(&database.Metric{}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    50000,
			"message": "Failed to delete metric",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
	})
}
