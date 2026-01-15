package wizard

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/taliove/go-install-claude/internal/tui/styles"
	"github.com/taliove/go-install-claude/internal/tui/theme"
)

// SelectorItem represents an item in the selector
type SelectorItem struct {
	ID          string
	Name        string
	Description string
	Badge       string
	Disabled    bool
}

// Selector represents a selection component
type Selector struct {
	items    []SelectorItem
	selected int
	width    int
	title    string
}

// NewSelector creates a new selector
func NewSelector(items []SelectorItem) *Selector {
	return &Selector{
		items:    items,
		selected: 0,
		width:    50,
	}
}

// SetTitle sets the selector title
func (s *Selector) SetTitle(title string) {
	s.title = title
}

// SetWidth sets the selector width
func (s *Selector) SetWidth(width int) {
	s.width = width
}

// SetSelected sets the selected index
func (s *Selector) SetSelected(index int) {
	if index >= 0 && index < len(s.items) {
		s.selected = index
	}
}

// Selected returns the selected index
func (s *Selector) Selected() int {
	return s.selected
}

// SelectedItem returns the selected item
func (s *Selector) SelectedItem() *SelectorItem {
	if s.selected >= 0 && s.selected < len(s.items) {
		return &s.items[s.selected]
	}
	return nil
}

// Next moves to the next item
func (s *Selector) Next() {
	for i := 1; i <= len(s.items); i++ {
		next := (s.selected + i) % len(s.items)
		if !s.items[next].Disabled {
			s.selected = next
			return
		}
	}
}

// Prev moves to the previous item
func (s *Selector) Prev() {
	for i := 1; i <= len(s.items); i++ {
		prev := (s.selected - i + len(s.items)) % len(s.items)
		if !s.items[prev].Disabled {
			s.selected = prev
			return
		}
	}
}

// Render renders the selector
func (s *Selector) Render() string {
	t := theme.Current()

	var content strings.Builder

	// Title
	if s.title != "" {
		titleStyle := lipgloss.NewStyle().
			Foreground(t.Primary()).
			Bold(true)
		content.WriteString(titleStyle.Render(s.title))
		content.WriteString("\n\n")
	}

	// Items
	for i, item := range s.items {
		content.WriteString(s.renderItem(i, item))
		content.WriteString("\n")
	}

	return content.String()
}

// renderItem renders a single item
func (s *Selector) renderItem(index int, item SelectorItem) string {
	t := theme.Current()

	isSelected := index == s.selected

	// Cursor
	cursor := "  "
	if isSelected {
		cursor = styles.IconArrow + " "
	}

	// Name style
	var nameStyle lipgloss.Style
	if item.Disabled {
		nameStyle = lipgloss.NewStyle().Foreground(t.TextDim())
	} else if isSelected {
		nameStyle = lipgloss.NewStyle().Foreground(t.Accent()).Bold(true)
	} else {
		nameStyle = lipgloss.NewStyle().Foreground(t.Text())
	}

	// Build line
	line := cursor + nameStyle.Render(item.Name)

	// Badge
	if item.Badge != "" {
		badgeStyle := lipgloss.NewStyle().
			Foreground(t.Warning()).
			Bold(true)
		line += " " + badgeStyle.Render(item.Badge)
	}

	// Description on next line
	if item.Description != "" {
		descStyle := lipgloss.NewStyle().Foreground(t.TextDim())
		line += "\n     " + descStyle.Render(item.Description)
	}

	return line
}

// RenderWithBorder renders the selector with a border
func (s *Selector) RenderWithBorder() string {
	t := theme.Current()

	content := s.Render()

	containerStyle := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(t.Primary()).
		Padding(1, 2).
		Width(s.width)

	return containerStyle.Render(content)
}

// ModelSelector creates a selector for Claude models
func ModelSelector(models []SelectorItem, defaultIndex int) *Selector {
	s := NewSelector(models)
	s.SetTitle(fmt.Sprintf("%s 选择模型", styles.IconPackage))
	s.SetSelected(defaultIndex)
	return s
}
