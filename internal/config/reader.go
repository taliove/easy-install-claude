package config

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
)

// ErrConfigNotFound 配置文件不存在
var ErrConfigNotFound = errors.New("配置文件不存在")

// ErrAPIKeyNotFound 配置中没有 API Key
var ErrAPIKeyNotFound = errors.New("未找到 API Key 配置")

// ExistingConfig 已存在的配置信息
type ExistingConfig struct {
	APIKey   string
	BaseURL  string
	Model    string
	FilePath string
}

// ReadExistingSettings 读取已存在的配置
func ReadExistingSettings(claudeDir string) (*ExistingConfig, error) {
	settingsPath := filepath.Join(claudeDir, "settings.json")

	data, err := os.ReadFile(settingsPath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, ErrConfigNotFound
		}
		return nil, err
	}

	var settings ClaudeSettings
	if err := json.Unmarshal(data, &settings); err != nil {
		return nil, err
	}

	config := &ExistingConfig{
		FilePath: settingsPath,
	}

	if settings.Env != nil {
		config.APIKey = settings.Env["ANTHROPIC_API_KEY"]
		config.BaseURL = settings.Env["ANTHROPIC_BASE_URL"]
		config.Model = settings.Env["ANTHROPIC_MODEL"]
	}

	return config, nil
}

// HasExistingConfig 检查是否存在配置
func HasExistingConfig(claudeDir string) bool {
	settingsPath := filepath.Join(claudeDir, "settings.json")
	_, err := os.Stat(settingsPath)
	return err == nil
}

// UpdateModel 仅更新模型设置，保留其他配置
func UpdateModel(claudeDir, model string) error {
	settingsPath := filepath.Join(claudeDir, "settings.json")

	// 读取现有配置
	data, err := os.ReadFile(settingsPath)
	if err != nil {
		return err
	}

	var settings ClaudeSettings
	if err := json.Unmarshal(data, &settings); err != nil {
		return err
	}

	// 确保 Env map 存在
	if settings.Env == nil {
		settings.Env = make(map[string]string)
	}

	// 更新模型
	settings.Env["ANTHROPIC_MODEL"] = model

	// 写回配置
	newData, err := json.MarshalIndent(settings, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(settingsPath, newData, 0o600)
}

// GetModelByID 根据 ID 获取模型信息
func GetModelByID(id string) *ModelInfo {
	for _, m := range SupportedModels {
		if m.ID == id {
			return &m
		}
	}
	return nil
}

// GetModelByShortName 根据简短名称获取模型（用于命令行）
func GetModelByShortName(name string) *ModelInfo {
	// 支持的简短名称映射
	shortNames := map[string]string{
		"sonnet-4":   "claude-sonnet-4-20250514",
		"sonnet-4.5": "claude-sonnet-4-5-20250929",
		"haiku-4.5":  "claude-haiku-4-5-20251001",
		"opus-4.1":   "claude-opus-4-1-20250805",
		"opus-4.5":   "claude-opus-4-5-20251101",
		// 完整名称也支持
		"claude-sonnet-4-20250514":   "claude-sonnet-4-20250514",
		"claude-sonnet-4-5-20250929": "claude-sonnet-4-5-20250929",
		"claude-haiku-4-5-20251001":  "claude-haiku-4-5-20251001",
		"claude-opus-4-1-20250805":   "claude-opus-4-1-20250805",
		"claude-opus-4-5-20251101":   "claude-opus-4-5-20251101",
	}

	if fullName, ok := shortNames[name]; ok {
		return GetModelByID(fullName)
	}
	return nil
}

// ListModels 返回所有支持的模型列表（用于帮助信息）
func ListModels() string {
	result := "支持的模型:\n"
	for _, m := range SupportedModels {
		defaultMark := ""
		if m.Default {
			defaultMark = " (默认)"
		}
		result += "  " + m.ID + defaultMark + "\n"
		result += "    " + m.Name + " - " + m.Description + "\n"
	}
	return result
}
