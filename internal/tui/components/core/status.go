package core

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/lipgloss"

	"github.com/taliove/go-install-claude/internal/tui/styles"
	"github.com/taliove/go-install-claude/internal/tui/theme"
)

// StatusBar represents the bottom status bar
type StatusBar struct {
	width int
	items []StatusItem
}

// StatusItem represents an item in the status bar
type StatusItem struct {
	Label string
	Value string
	Type  StatusType
}

// StatusType defines the type of status item
type StatusType int

const (
	StatusNormal StatusType = iota
	StatusSuccess
	StatusError
	StatusWarning
	StatusInfo
)

// NewStatusBar creates a new status bar
func NewStatusBar(width int) *StatusBar {
	return &StatusBar{
		width: width,
		items: make([]StatusItem, 0),
	}
}

// SetWidth sets the status bar width
func (s *StatusBar) SetWidth(width int) {
	s.width = width
}

// SetItems sets the status bar items
func (s *StatusBar) SetItems(items []StatusItem) {
	s.items = items
}

// AddItem adds an item to the status bar
func (s *StatusBar) AddItem(item StatusItem) {
	s.items = append(s.items, item)
}

// Clear clears all items
func (s *StatusBar) Clear() {
	s.items = make([]StatusItem, 0)
}

// Render renders the status bar
func (s *StatusBar) Render() string {
	t := theme.Current()

	// Base status bar style
	barStyle := lipgloss.NewStyle().
		Background(t.BackgroundSecondary()).
		Foreground(t.TextMuted()).
		Width(s.width)

	if len(s.items) == 0 {
		return barStyle.Render("")
	}

	// Render each item
	var parts []string
	for _, item := range s.items {
		parts = append(parts, s.renderItem(item))
	}

	content := strings.Join(parts, s.renderSeparator())
	return barStyle.Render(content)
}

// renderItem renders a single status item
func (s *StatusBar) renderItem(item StatusItem) string {
	t := theme.Current()

	var valueStyle lipgloss.Style
	var icon string

	switch item.Type {
	case StatusSuccess:
		valueStyle = lipgloss.NewStyle().Foreground(t.Success())
		icon = styles.IconCheck + " "
	case StatusError:
		valueStyle = lipgloss.NewStyle().Foreground(t.Error())
		icon = styles.IconCross + " "
	case StatusWarning:
		valueStyle = lipgloss.NewStyle().Foreground(t.Warning())
		icon = styles.IconWarning + " "
	case StatusInfo:
		valueStyle = lipgloss.NewStyle().Foreground(t.Info())
		icon = styles.IconInfo + " "
	default:
		valueStyle = lipgloss.NewStyle().Foreground(t.Text())
		icon = ""
	}

	labelStyle := lipgloss.NewStyle().Foreground(t.TextMuted())

	if item.Label != "" {
		return fmt.Sprintf(" %s%s %s",
			labelStyle.Render(item.Label+":"),
			icon,
			valueStyle.Render(item.Value))
	}
	return fmt.Sprintf(" %s%s", icon, valueStyle.Render(item.Value))
}

// renderSeparator renders a separator between items
func (s *StatusBar) renderSeparator() string {
	t := theme.Current()
	sepStyle := lipgloss.NewStyle().Foreground(t.BorderDim())
	return sepStyle.Render(" │ ")
}

// RenderHelpBadge renders the help keyboard shortcut badge
func RenderHelpBadge(key, label string) string {
	t := theme.Current()

	keyStyle := lipgloss.NewStyle().
		Foreground(t.Background()).
		Background(t.TextMuted()).
		Padding(0, 1).
		Bold(true)

	labelStyle := lipgloss.NewStyle().
		Foreground(t.TextMuted())

	return keyStyle.Render(key) + labelStyle.Render(" "+label)
}
