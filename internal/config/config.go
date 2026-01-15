package config

import (
	"encoding/json"
	"os"
	"path/filepath"
)

// 万界代理配置
const (
	WanjieBaseURL = "https://maas-openapi.wanjiedata.com/api/anthropic"
	WanjieName    = "万界数据"
)

// 支持的模型列表
var SupportedModels = []ModelInfo{
	{ID: "claude-sonnet-4-20250514", Name: "Claude Sonnet 4", Description: "性价比之选，推荐日常使用", Default: true},
	{ID: "claude-sonnet-4-5-20250929", Name: "Claude Sonnet 4.5", Description: "增强版 Sonnet，更强推理能力"},
	{ID: "claude-haiku-4-5-20251001", Name: "Claude Haiku 4.5", Description: "快速响应，适合简单任务"},
	{ID: "claude-opus-4-1-20250805", Name: "Claude Opus 4.1", Description: "强大性能，适合复杂任务"},
	{ID: "claude-opus-4-5-20251101", Name: "Claude Opus 4.5", Description: "旗舰模型，最强性能"},
}

// ModelInfo 模型信息
type ModelInfo struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Default     bool   `json:"default,omitempty"`
}

// ClaudeSettings Claude Code 配置结构
type ClaudeSettings struct {
	Env         map[string]string `json:"env"`
	Permissions *Permissions      `json:"permissions,omitempty"`
}

// Permissions 权限配置
type Permissions struct {
	Allow []string `json:"allow,omitempty"`
	Deny  []string `json:"deny,omitempty"`
}

// InstallConfig 安装配置
type InstallConfig struct {
	APIKey   string // 万界 API Key
	Model    string // 选择的模型
	BaseURL  string // API 基础地址
	Provider string // 提供商名称
}

// NewDefaultConfig 创建默认配置
func NewDefaultConfig() *InstallConfig {
	return &InstallConfig{
		BaseURL:  WanjieBaseURL,
		Provider: WanjieName,
		Model:    GetDefaultModel().ID,
	}
}

// GetDefaultModel 获取默认模型
func GetDefaultModel() ModelInfo {
	for _, m := range SupportedModels {
		if m.Default {
			return m
		}
	}
	return SupportedModels[0]
}

// GenerateSettings 生成 Claude settings.json 内容
func (c *InstallConfig) GenerateSettings() *ClaudeSettings {
	return &ClaudeSettings{
		Env: map[string]string{
			"ANTHROPIC_BASE_URL": c.BaseURL,
			"ANTHROPIC_API_KEY":  c.APIKey,
			"ANTHROPIC_MODEL":    c.Model,
		},
	}
}

// WriteSettings 写入配置文件
func (c *InstallConfig) WriteSettings(claudeDir string) error {
	// 确保 .claude 目录存在
	if err := os.MkdirAll(claudeDir, 0o755); err != nil {
		return err
	}

	settingsPath := filepath.Join(claudeDir, "settings.json")
	settings := c.GenerateSettings()

	data, err := json.MarshalIndent(settings, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(settingsPath, data, 0o600)
}

// ValidateAPIKey 验证 API Key 格式
func ValidateAPIKey(key string) bool {
	// 万界 API Key 格式验证（简单检查长度）
	return len(key) >= 10
}
