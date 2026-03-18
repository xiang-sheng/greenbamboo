package database

// GetPresetMetrics 获取预置健康指标
func GetPresetMetrics() []Metric {
	return []Metric{
		{
			Name:     "体重",
			Type:     "number",
			Unit:     "kg",
			IsPreset: true,
		},
		{
			Name:     "睡眠时长",
			Type:     "number",
			Unit:     "hours",
			IsPreset: true,
		},
		{
			Name:     "睡眠质量",
			Type:     "number",
			Unit:     "1-5",
			IsPreset: true,
		},
		{
			Name:     "步数",
			Type:     "number",
			Unit:     "steps",
			IsPreset: true,
		},
		{
			Name:     "心情",
			Type:     "number",
			Unit:     "1-5",
			IsPreset: true,
		},
		{
			Name:     "血压（收缩压）",
			Type:     "number",
			Unit:     "mmHg",
			IsPreset: true,
		},
		{
			Name:     "血压（舒张压）",
			Type:     "number",
			Unit:     "mmHg",
			IsPreset: true,
		},
		{
			Name:     "心率",
			Type:     "number",
			Unit:     "bpm",
			IsPreset: true,
		},
		{
			Name:     "血糖",
			Type:     "number",
			Unit:     "mmol/L",
			IsPreset: true,
		},
		{
			Name:     "运动时长",
			Type:     "number",
			Unit:     "minutes",
			IsPreset: true,
		},
	}
}
