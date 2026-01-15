package core

import (
	"strings"

	"github.com/charmbracelet/lipgloss"

	"github.com/taliove/go-install-claude/internal/tui/theme"
)

// Logo text art
const logoArt = `
 ██████╗██╗      █████╗ ██╗   ██╗██████╗ ███████╗
██╔════╝██║     ██╔══██╗██║   ██║██╔══██╗██╔════╝
██║     ██║     ███████║██║   ██║██║  ██║█████╗  
██║     ██║     ██╔══██║██║   ██║██║  ██║██╔══╝  
╚██████╗███████╗██║  ██║╚██████╔╝██████╔╝███████╗
 ╚═════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝`

// Simple logo for smaller terminals
const logoSimple = `Claude Code`

// LogoConfig configures logo rendering
type LogoConfig struct {
	ShowArt    bool
	Title      string
	Subtitle   string
	ShowBorder bool
	Width      int
}

// DefaultLogoConfig returns default logo configuration
func DefaultLogoConfig() LogoConfig {
	return LogoConfig{
		ShowArt:    true,
		Title:      "一键安装工具",
		Subtitle:   "⚡ 万界数据 ⚡",
		ShowBorder: true,
		Width:      0,
	}
}

// RenderLogo renders the application logo
func RenderLogo(config LogoConfig) string {
	t := theme.Current()

	var content strings.Builder

	// Art or simple logo
	if config.ShowArt {
		artStyle := lipgloss.NewStyle().
			Foreground(t.Primary()).
			Bold(true)
		content.WriteString(artStyle.Render(strings.TrimPrefix(logoArt, "\n")))
		content.WriteString("\n")
	} else {
		titleStyle := lipgloss.NewStyle().
			Foreground(t.Accent()).
			Bold(true)
		content.WriteString(titleStyle.Render(logoSimple))
		content.WriteString("\n")
	}

	// Title
	if config.Title != "" {
		titleStyle := lipgloss.NewStyle().
			Foreground(t.Accent()).
			Bold(true)
		content.WriteString(titleStyle.Render(config.Title))
		content.WriteString("\n")
	}

	// Subtitle
	if config.Subtitle != "" {
		subtitleStyle := lipgloss.NewStyle().
			Foreground(t.Warning())
		content.WriteString(subtitleStyle.Render(config.Subtitle))
	}

	result := content.String()

	// Optional border
	if config.ShowBorder {
		boxStyle := lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(t.Primary()).
			Padding(1, 4).
			Align(lipgloss.Center)

		if config.Width > 0 {
			boxStyle = boxStyle.Width(config.Width)
		}

		result = boxStyle.Render(result)
	} else {
		centerStyle := lipgloss.NewStyle().
			Align(lipgloss.Center)
		result = centerStyle.Render(result)
	}

	return result
}

// RenderSimpleLogo renders a simple text logo
func RenderSimpleLogo() string {
	t := theme.Current()

	titleStyle := lipgloss.NewStyle().
		Foreground(t.Accent()).
		Bold(true)

	subtitleStyle := lipgloss.NewStyle().
		Foreground(t.Warning())

	boxStyle := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(t.Primary()).
		Padding(1, 4).
		Align(lipgloss.Center)

	content := lipgloss.JoinVertical(lipgloss.Center,
		titleStyle.Render("Claude Code 一键安装工具"),
		subtitleStyle.Render("⚡ 万界数据 ⚡"),
	)

	return boxStyle.Render(content)
}
