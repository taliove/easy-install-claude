package dialog

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/taliove/go-install-claude/internal/tui/styles"
	"github.com/taliove/go-install-claude/internal/tui/theme"
)

// HelpItem represents a help entry
type HelpItem struct {
	Key         string
	Description string
}

// HelpDialog shows keyboard shortcuts and help
type HelpDialog struct {
	Title  string
	Items  []HelpItem
	Width  int
	Shadow bool
}

// NewHelpDialog creates a help dialog
func NewHelpDialog() *HelpDialog {
	return &HelpDialog{
		Title:  "键盘快捷键",
		Width:  45,
		Shadow: true,
		Items: []HelpItem{
			{Key: "Enter", Description: "确认 / 继续"},
			{Key: "Esc", Description: "返回 / 取消"},
			{Key: "↑/↓", Description: "上下选择"},
			{Key: "q", Description: "退出程序"},
			{Key: "?", Description: "显示帮助"},
		},
	}
}

// WithItems sets custom help items
func (h *HelpDialog) WithItems(items []HelpItem) *HelpDialog {
	h.Items = items
	return h
}

// AddItem adds a help item
func (h *HelpDialog) AddItem(key, description string) *HelpDialog {
	h.Items = append(h.Items, HelpItem{Key: key, Description: description})
	return h
}

// Render renders the help dialog
func (h *HelpDialog) Render() string {
	t := theme.Current()

	var content strings.Builder

	// Title
	titleStyle := lipgloss.NewStyle().
		Foreground(t.Primary()).
		Bold(true)
	content.WriteString(titleStyle.Render(styles.IconInfo + " " + h.Title))
	content.WriteString("\n\n")

	// Help items
	keyStyle := lipgloss.NewStyle().
		Foreground(t.Accent()).
		Width(12).
		Bold(true)

	descStyle := lipgloss.NewStyle().
		Foreground(t.Text())

	for _, item := range h.Items {
		content.WriteString(keyStyle.Render(item.Key))
		content.WriteString(descStyle.Render(item.Description))
		content.WriteString("\n")
	}

	// Footer
	content.WriteString("\n")
	footerStyle := lipgloss.NewStyle().
		Foreground(t.TextDim())
	content.WriteString(footerStyle.Render("按 Esc 关闭"))

	// Container
	containerStyle := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(t.Primary()).
		Padding(1, 2).
		Width(h.Width)

	result := containerStyle.Render(content.String())

	if h.Shadow {
		result = addShadow(result)
	}

	return result
}
