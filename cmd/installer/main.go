package main

import (
	"flag"
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/taliove/go-install-claude/internal/config"
	"github.com/taliove/go-install-claude/internal/detector"
	"github.com/taliove/go-install-claude/internal/tui"
	"github.com/taliove/go-install-claude/internal/version"
)

func main() {
	// 命令行参数
	switchModel := flag.Bool("switch-model", false, "交互式切换模型")
	showConfig := flag.Bool("config", false, "显示当前配置")
	showVersion := flag.Bool("version", false, "显示版本信息")
	listModels := flag.Bool("list-models", false, "列出所有支持的模型")
	flag.Parse()

	// 显示版本
	if *showVersion {
		printVersion()
		return
	}

	// 列出模型
	if *listModels {
		fmt.Print(config.ListModels())
		return
	}

	// 显示当前配置
	if *showConfig {
		showCurrentConfig()
		return
	}

	// 切换模型模式
	if *switchModel {
		runSwitchModelMode()
		return
	}

	// 默认：完整安装向导
	runFullInstaller()
}

// printVersion 打印版本信息
func printVersion() {
	fmt.Printf("Claude Code Installer %s\n", version.GetFullVersion())
	fmt.Println()
	fmt.Println("一键安装 Claude Code 并配置万界数据代理")
	fmt.Println("项目地址: https://github.com/taliove/go-install-claude")
}

// showCurrentConfig 显示当前配置
func showCurrentConfig() {
	// 获取 Claude 配置目录
	info, err := detector.Detect()
	if err != nil {
		fmt.Printf("❌ 无法检测系统环境: %v\n", err)
		os.Exit(1)
	}

	// 读取现有配置
	existing, err := config.ReadExistingSettings(info.ClaudeDir)
	if err != nil {
		if err == config.ErrConfigNotFound {
			fmt.Println("❌ 未找到配置文件")
			fmt.Println()
			fmt.Println("请先运行安装向导:")
			fmt.Println("  claude-installer")
			return
		}
		fmt.Printf("❌ 读取配置失败: %v\n", err)
		os.Exit(1)
	}

	// 显示配置信息
	fmt.Println("📋 当前配置")
	fmt.Println()
	fmt.Printf("  配置文件: %s\n", existing.FilePath)
	fmt.Printf("  API 地址: %s\n", existing.BaseURL)
	fmt.Printf("  当前模型: %s\n", existing.Model)

	// 显示模型详情
	if modelInfo := config.GetModelByID(existing.Model); modelInfo != nil {
		fmt.Printf("             %s - %s\n", modelInfo.Name, modelInfo.Description)
	}

	// API Key 脱敏显示
	if existing.APIKey != "" {
		maskedKey := maskAPIKey(existing.APIKey)
		fmt.Printf("  API Key:  %s\n", maskedKey)
	} else {
		fmt.Println("  API Key:  (未配置)")
	}

	fmt.Println()
	fmt.Println("💡 切换模型:")
	fmt.Println("  claude-installer --switch-model")
}

// maskAPIKey 遮蔽 API Key
func maskAPIKey(key string) string {
	if len(key) <= 8 {
		return "****"
	}
	return key[:4] + "****" + key[len(key)-4:]
}

// runSwitchModelMode 运行模型切换模式
func runSwitchModelMode() {
	// 获取 Claude 配置目录
	info, err := detector.Detect()
	if err != nil {
		fmt.Printf("❌ 无法检测系统环境: %v\n", err)
		os.Exit(1)
	}

	// 检查是否存在配置
	existing, err := config.ReadExistingSettings(info.ClaudeDir)
	if err != nil {
		if err == config.ErrConfigNotFound {
			fmt.Println("❌ 未找到已有配置")
			fmt.Println()
			fmt.Println("请先运行完整安装向导:")
			fmt.Println("  claude-installer")
			return
		}
		fmt.Printf("❌ 读取配置失败: %v\n", err)
		os.Exit(1)
	}

	// 检查 API Key
	if existing.APIKey == "" {
		fmt.Println("❌ 配置中没有 API Key")
		fmt.Println()
		fmt.Println("请先运行完整安装向导配置 API Key:")
		fmt.Println("  claude-installer")
		return
	}

	// 启动模型切换 TUI
	p := tea.NewProgram(
		tui.NewSwitchModelModel(info.ClaudeDir, existing.Model),
		tea.WithAltScreen(),
		tea.WithMouseCellMotion(),
	)

	if _, err := p.Run(); err != nil {
		fmt.Printf("程序运行出错: %v\n", err)
		os.Exit(1)
	}
}

// runFullInstaller 运行完整安装向导
func runFullInstaller() {
	p := tea.NewProgram(
		tui.NewModel(),
		tea.WithAltScreen(),
		tea.WithMouseCellMotion(),
	)

	if _, err := p.Run(); err != nil {
		fmt.Printf("程序运行出错: %v\n", err)
		os.Exit(1)
	}
}
