package wizard

import (
	"strings"

	"github.com/charmbracelet/lipgloss"

	"github.com/taliove/go-install-claude/internal/tui/styles"
	"github.com/taliove/go-install-claude/internal/tui/theme"
)

// ConfigItem represents a configuration item
type ConfigItem struct {
	Label  string
	Value  string
	Masked bool
}

// ConfigCard displays configuration summary
type ConfigCard struct {
	title  string
	items  []ConfigItem
	width  int
	footer string
}

// NewConfigCard creates a new config card
func NewConfigCard(title string) *ConfigCard {
	return &ConfigCard{
		title: title,
		items: make([]ConfigItem, 0),
		width: 50,
	}
}

// SetWidth sets the card width
func (c *ConfigCard) SetWidth(width int) {
	c.width = width
}

// SetFooter sets the card footer
func (c *ConfigCard) SetFooter(footer string) {
	c.footer = footer
}

// AddItem adds a configuration item
func (c *ConfigCard) AddItem(label, value string, masked bool) {
	c.items = append(c.items, ConfigItem{
		Label:  label,
		Value:  value,
		Masked: masked,
	})
}

// SetItems sets all configuration items
func (c *ConfigCard) SetItems(items []ConfigItem) {
	c.items = items
}

// Render renders the config card
func (c *ConfigCard) Render() string {
	t := theme.Current()

	var content strings.Builder

	// Title
	if c.title != "" {
		titleStyle := lipgloss.NewStyle().
			Foreground(t.Primary()).
			Bold(true)
		content.WriteString(titleStyle.Render(styles.IconPackage + " " + c.title))
		content.WriteString("\n\n")
	}

	// Items
	labelWidth := 0
	for _, item := range c.items {
		if len(item.Label) > labelWidth {
			labelWidth = len(item.Label)
		}
	}

	labelStyle := lipgloss.NewStyle().
		Foreground(t.TextMuted()).
		Width(labelWidth + 2)

	valueStyle := lipgloss.NewStyle().
		Foreground(t.Text())

	for _, item := range c.items {
		value := item.Value
		if item.Masked {
			value = maskValue(value)
		}
		content.WriteString(labelStyle.Render(item.Label + ":"))
		content.WriteString(valueStyle.Render(value))
		content.WriteString("\n")
	}

	// Footer
	if c.footer != "" {
		content.WriteString("\n")
		footerStyle := lipgloss.NewStyle().Foreground(t.TextDim())
		content.WriteString(footerStyle.Render(c.footer))
	}

	// Container
	containerStyle := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(t.Border()).
		Padding(1, 2).
		Width(c.width)

	return containerStyle.Render(content.String())
}

// maskValue masks a sensitive value
func maskValue(value string) string {
	if len(value) <= 8 {
		return "****"
	}
	return value[:4] + "..." + value[len(value)-4:]
}

// SystemInfoCard creates a card showing system information
func SystemInfoCard(os, nodeVersion, npmVersion string, canReachAPI bool) string {
	t := theme.Current()

	var content strings.Builder

	titleStyle := lipgloss.NewStyle().
		Foreground(t.Primary()).
		Bold(true)
	content.WriteString(titleStyle.Render(styles.IconGear + " 系统环境"))
	content.WriteString("\n\n")

	// System info items
	items := []struct {
		label   string
		value   string
		success bool
	}{
		{"操作系统", os, true},
		{"Node.js", nodeVersion, nodeVersion != ""},
		{"npm", npmVersion, npmVersion != ""},
		{"API 连接", "已连接", canReachAPI},
	}

	labelStyle := lipgloss.NewStyle().
		Foreground(t.TextMuted()).
		Width(12)

	for _, item := range items {
		var icon string
		var valueStyle lipgloss.Style

		if item.success {
			icon = styles.IconCheck
			valueStyle = lipgloss.NewStyle().Foreground(t.Success())
		} else {
			icon = styles.IconCross
			valueStyle = lipgloss.NewStyle().Foreground(t.Error())
		}

		content.WriteString(labelStyle.Render(item.label))
		content.WriteString(valueStyle.Render(icon + " " + item.value))
		content.WriteString("\n")
	}

	containerStyle := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(t.Border()).
		Padding(1, 2)

	return containerStyle.Render(content.String())
}
