package dialog

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/taliove/go-install-claude/internal/tui/styles"
	"github.com/taliove/go-install-claude/internal/tui/theme"
)

// DialogType represents the type of dialog
type DialogType int

const (
	DialogInfo DialogType = iota
	DialogSuccess
	DialogWarning
	DialogError
	DialogConfirm
)

// Dialog represents a modal dialog
type Dialog struct {
	Type    DialogType
	Title   string
	Message string
	Width   int
	Buttons []string
	Focused int
	Shadow  bool
}

// NewDialog creates a new dialog
func NewDialog(dialogType DialogType, title, message string) *Dialog {
	return &Dialog{
		Type:    dialogType,
		Title:   title,
		Message: message,
		Width:   50,
		Buttons: []string{},
		Focused: 0,
		Shadow:  true,
	}
}

// WithButtons adds buttons to the dialog
func (d *Dialog) WithButtons(buttons ...string) *Dialog {
	d.Buttons = buttons
	return d
}

// WithWidth sets the dialog width
func (d *Dialog) WithWidth(width int) *Dialog {
	d.Width = width
	return d
}

// WithShadow enables/disables shadow
func (d *Dialog) WithShadow(shadow bool) *Dialog {
	d.Shadow = shadow
	return d
}

// SetFocused sets the focused button index
func (d *Dialog) SetFocused(index int) {
	if index >= 0 && index < len(d.Buttons) {
		d.Focused = index
	}
}

// NextButton moves focus to the next button
func (d *Dialog) NextButton() {
	if len(d.Buttons) > 0 {
		d.Focused = (d.Focused + 1) % len(d.Buttons)
	}
}

// PrevButton moves focus to the previous button
func (d *Dialog) PrevButton() {
	if len(d.Buttons) > 0 {
		d.Focused = (d.Focused - 1 + len(d.Buttons)) % len(d.Buttons)
	}
}

// Render renders the dialog
func (d *Dialog) Render() string {
	t := theme.Current()

	// Determine colors based on type
	var borderColor lipgloss.AdaptiveColor
	var icon string

	switch d.Type {
	case DialogSuccess:
		borderColor = t.Success()
		icon = styles.IconCheck
	case DialogWarning:
		borderColor = t.Warning()
		icon = styles.IconWarning
	case DialogError:
		borderColor = t.Error()
		icon = styles.IconError
	case DialogConfirm:
		borderColor = t.Info()
		icon = styles.IconInfo
	default:
		borderColor = t.Primary()
		icon = styles.IconInfo
	}

	// Build content
	var content strings.Builder

	// Title with icon
	if d.Title != "" {
		titleStyle := lipgloss.NewStyle().
			Foreground(borderColor).
			Bold(true)
		content.WriteString(titleStyle.Render(icon + " " + d.Title))
		content.WriteString("\n\n")
	}

	// Message
	messageStyle := lipgloss.NewStyle().
		Foreground(t.Text()).
		Width(d.Width - 6)
	content.WriteString(messageStyle.Render(d.Message))

	// Buttons
	if len(d.Buttons) > 0 {
		content.WriteString("\n\n")
		content.WriteString(d.renderButtons())
	}

	// Container
	containerStyle := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(borderColor).
		Padding(1, 2).
		Width(d.Width)

	result := containerStyle.Render(content.String())

	// Add shadow
	if d.Shadow {
		result = addShadow(result)
	}

	return result
}

// renderButtons renders the dialog buttons
func (d *Dialog) renderButtons() string {
	t := theme.Current()

	var buttons []string
	for i, label := range d.Buttons {
		var style lipgloss.Style
		if i == d.Focused {
			style = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#FFFFFF")).
				Background(t.Primary()).
				Padding(0, 3).
				Bold(true)
		} else {
			style = lipgloss.NewStyle().
				Foreground(t.TextMuted()).
				Background(t.BackgroundSecondary()).
				Padding(0, 3)
		}
		buttons = append(buttons, style.Render(label))
	}

	return lipgloss.JoinHorizontal(lipgloss.Center, buttons...)
}

// addShadow adds a drop shadow effect
func addShadow(content string) string {
	lines := strings.Split(content, "\n")

	shadowChar := "░"

	var result []string
	for _, line := range lines {
		result = append(result, line+shadowChar+shadowChar)
	}

	// Bottom shadow
	if len(lines) > 0 {
		width := lipgloss.Width(lines[0]) + 2
		result = append(result, "  "+strings.Repeat(shadowChar, width))
	}

	return strings.Join(result, "\n")
}

// Confirm creates a confirmation dialog
func Confirm(title, message string) *Dialog {
	return NewDialog(DialogConfirm, title, message).
		WithButtons("确认", "取消")
}

// Error creates an error dialog
func Error(title, message string) *Dialog {
	return NewDialog(DialogError, title, message).
		WithButtons("确定")
}

// Success creates a success dialog
func Success(title, message string) *Dialog {
	return NewDialog(DialogSuccess, title, message).
		WithButtons("确定")
}

// Warning creates a warning dialog
func Warning(title, message string) *Dialog {
	return NewDialog(DialogWarning, title, message).
		WithButtons("确定")
}

// Info creates an info dialog
func Info(title, message string) *Dialog {
	return NewDialog(DialogInfo, title, message).
		WithButtons("确定")
}
