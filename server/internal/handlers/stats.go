package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"github.com/greenbamboo/server/internal/database"
)

// TrendStatsRequest 趋势统计请求
type TrendStatsRequest struct {
	MetricID string `form:"metric_id" binding:"required"`
	Days     int    `form:"days" binding:"omitempty,min=1,max=365"`
}

// TrendDataPoint 趋势数据点
type TrendDataPoint struct {
	Time  int64   `json:"time"`  // 时间戳（天）
	Value float64 `json:"value"`
}

// GetTrendStats 获取趋势统计
func GetTrendStats(c *gin.Context) {
	userID := c.GetString("userID")
	var req TrendStatsRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    40000,
			"message": err.Error(),
		})
		return
	}

	if req.Days == 0 {
		req.Days = 30
	}

	db := c.MustGet("db").(*gorm.DB)

	// 查询指定天数的数据
	var records []database.HealthRecord
	if err := db.Where("user_id = ? AND metric_id = ?", userID, req.MetricID).
		Order("recorded_at ASC").
		Find(&records).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    50000,
			"message": "Failed to get trend data",
		})
		return
	}

	// 按天聚合
	dailyData := make(map[int64]float64)
	for _, r := range records {
		day := r.RecordedAt / 86400 // 转换为天
		dailyData[day] = r.Value
	}

	// 转换为数组
	dataPoints := make([]TrendDataPoint, 0, len(dailyData))
	for day, value := range dailyData {
		dataPoints = append(dataPoints, TrendDataPoint{
			Time:  day * 86400,
			Value: value,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data": gin.H{
			"metric_id": req.MetricID,
			"days":      req.Days,
			"points":    dataPoints,
		},
	})
}

// SummaryStatsRequest 汇总统计请求
type SummaryStatsRequest struct {
	MetricID string `form:"metric_id"`
	Days     int    `form:"days" binding:"omitempty,min=1,max=365"`
}

// SummaryStats 汇总统计结果
type SummaryStats struct {
	Count     int     `json:"count"`
	Avg       float64 `json:"avg"`
	Min       float64 `json:"min"`
	Max       float64 `json:"max"`
	Latest    float64 `json:"latest"`
	Trend     string  `json:"trend"` // "up", "down", "stable"
}

// GetSummaryStats 获取汇总统计
func GetSummaryStats(c *gin.Context) {
	userID := c.GetString("userID")
	var req SummaryStatsRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    40000,
			"message": err.Error(),
		})
		return
	}

	if req.Days == 0 {
		req.Days = 30
	}

	db := c.MustGet("db").(*gorm.DB)

	// 构建查询
	query := db.Where("user_id = ?", userID)
	if req.MetricID != "" {
		query = query.Where("metric_id = ?", req.MetricID)
	}

	var records []database.HealthRecord
	if err := query.Find(&records).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    50000,
			"message": "Failed to get summary data",
		})
		return
	}

	if len(records) == 0 {
		c.JSON(http.StatusOK, gin.H{
			"code":    0,
			"message": "success",
			"data": SummaryStats{
				Count:  0,
				Avg:    0,
				Min:    0,
				Max:    0,
				Latest: 0,
				Trend:  "stable",
			},
		})
		return
	}

	// 计算统计
	var sum, min, max float64
	min = records[0].Value
	max = records[0].Value

	for _, r := range records {
		sum += r.Value
		if r.Value < min {
			min = r.Value
		}
		if r.Value > max {
			max = r.Value
		}
	}

	avg := sum / float64(len(records))

	// 计算趋势（对比前一半和后一半）
	mid := len(records) / 2
	var firstHalfAvg, secondHalfAvg float64
	for i, r := range records {
		if i < mid {
			firstHalfAvg += r.Value
		} else {
			secondHalfAvg += r.Value
		}
	}
	firstHalfAvg /= float64(mid)
	secondHalfAvg /= float64(len(records) - mid)

	trend := "stable"
	if secondHalfAvg > firstHalfAvg*1.05 {
		trend = "up"
	} else if secondHalfAvg < firstHalfAvg*0.95 {
		trend = "down"
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "success",
		"data": SummaryStats{
			Count:  len(records),
			Avg:    avg,
			Min:    min,
			Max:    max,
			Latest: records[len(records)-1].Value,
			Trend:  trend,
		},
	})
}
