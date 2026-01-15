// Package styles provides style helpers for the TUI
package styles

import (
	"github.com/charmbracelet/lipgloss"

	"github.com/taliove/go-install-claude/internal/tui/theme"
)

// BaseStyle returns the base style using current theme
func BaseStyle() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(t.Text())
}

// Bold returns a bold text style
func Bold() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(t.Text()).
		Bold(true)
}

// Muted returns a muted text style
func Muted() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(t.TextMuted())
}

// Dim returns a dim text style
func Dim() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(t.TextDim())
}

// Primary returns primary colored text
func Primary() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(t.Primary())
}

// Accent returns accent colored text
func Accent() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(t.Accent()).
		Bold(true)
}

// Success returns success styled text
func Success() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(t.Success())
}

// Error returns error styled text
func Error() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(t.Error())
}

// Warning returns warning styled text
func Warning() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(t.Warning())
}

// Info returns info styled text
func Info() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(t.Info())
}

// Title returns a title style
func Title() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(t.Primary()).
		Bold(true).
		MarginBottom(1)
}

// Subtitle returns a subtitle style
func Subtitle() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(t.TextMuted()).
		MarginBottom(1)
}

// Help returns help text style
func Help() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(t.TextDim()).
		MarginTop(1)
}

// Border returns a bordered style
func Border() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(t.Border()).
		Padding(1, 2)
}

// FocusedBorder returns a focused bordered style
func FocusedBorder() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(t.BorderFocused()).
		Padding(1, 2)
}

// DimBorder returns a dim bordered style
func DimBorder() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(t.BorderDim()).
		Padding(1, 2)
}

// Card returns a card style
func Card() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(t.Border()).
		Padding(1, 2).
		MarginBottom(1)
}

// FocusedCard returns a focused card style
func FocusedCard() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(t.BorderFocused()).
		Padding(1, 2).
		MarginBottom(1)
}

// Padded returns a style with padding
func Padded() lipgloss.Style {
	return lipgloss.NewStyle().
		Padding(0, 1)
}

// Button returns a button style
func Button() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(lipgloss.Color("#FFFFFF")).
		Background(t.Primary()).
		Padding(0, 3).
		MarginRight(1)
}

// ButtonDisabled returns a disabled button style
func ButtonDisabled() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(t.TextDim()).
		Background(t.BackgroundSecondary()).
		Padding(0, 3).
		MarginRight(1)
}

// Badge returns a badge style
func Badge() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(t.Background()).
		Background(t.TextMuted()).
		Padding(0, 1).
		Bold(true)
}

// SuccessBadge returns a success badge style
func SuccessBadge() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(lipgloss.Color("#FFFFFF")).
		Background(t.Success()).
		Padding(0, 1).
		Bold(true)
}

// ErrorBadge returns an error badge style
func ErrorBadge() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(lipgloss.Color("#FFFFFF")).
		Background(t.Error()).
		Padding(0, 1).
		Bold(true)
}

// WarningBadge returns a warning badge style
func WarningBadge() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(lipgloss.Color("#000000")).
		Background(t.Warning()).
		Padding(0, 1).
		Bold(true)
}

// ListItem returns a list item style
func ListItem() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(t.Text()).
		PaddingLeft(2)
}

// ListItemSelected returns a selected list item style
func ListItemSelected() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(t.Accent()).
		Bold(true).
		PaddingLeft(2)
}

// ProgressBar returns a progress bar style
func ProgressBar() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(t.Primary())
}

// ProgressBarEmpty returns an empty progress bar style
func ProgressBarEmpty() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Foreground(t.BorderDim())
}

// StatusBar returns a status bar style
func StatusBar() lipgloss.Style {
	t := theme.Current()
	return lipgloss.NewStyle().
		Background(t.BackgroundSecondary()).
		Foreground(t.TextMuted()).
		Padding(0, 1)
}
