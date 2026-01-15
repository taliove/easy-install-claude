// Package layout provides layout components for the TUI
package layout

import (
	"strings"

	"github.com/charmbracelet/lipgloss"

	"github.com/taliove/go-install-claude/internal/tui/theme"
)

// Container wraps content with padding and borders
type Container struct {
	width  int
	height int

	paddingTop    int
	paddingRight  int
	paddingBottom int
	paddingLeft   int

	borderTop    bool
	borderRight  bool
	borderBottom bool
	borderLeft   bool

	borderStyle lipgloss.Border
	focused     bool
	title       string
}

// ContainerOption is a function that modifies a Container
type ContainerOption func(*Container)

// NewContainer creates a new container with options
func NewContainer(opts ...ContainerOption) *Container {
	c := &Container{
		borderStyle: lipgloss.RoundedBorder(),
	}
	for _, opt := range opts {
		opt(c)
	}
	return c
}

// WithPadding sets padding for all sides
func WithPadding(top, right, bottom, left int) ContainerOption {
	return func(c *Container) {
		c.paddingTop = top
		c.paddingRight = right
		c.paddingBottom = bottom
		c.paddingLeft = left
	}
}

// WithPaddingAll sets uniform padding
func WithPaddingAll(p int) ContainerOption {
	return func(c *Container) {
		c.paddingTop = p
		c.paddingRight = p
		c.paddingBottom = p
		c.paddingLeft = p
	}
}

// WithBorder sets which sides have borders
func WithBorder(top, right, bottom, left bool) ContainerOption {
	return func(c *Container) {
		c.borderTop = top
		c.borderRight = right
		c.borderBottom = bottom
		c.borderLeft = left
	}
}

// WithBorderAll enables borders on all sides
func WithBorderAll() ContainerOption {
	return func(c *Container) {
		c.borderTop = true
		c.borderRight = true
		c.borderBottom = true
		c.borderLeft = true
	}
}

// WithRoundedBorder sets rounded border style
func WithRoundedBorder() ContainerOption {
	return func(c *Container) {
		c.borderStyle = lipgloss.RoundedBorder()
	}
}

// WithThickBorder sets thick border style
func WithThickBorder() ContainerOption {
	return func(c *Container) {
		c.borderStyle = lipgloss.ThickBorder()
	}
}

// WithDoubleBorder sets double border style
func WithDoubleBorder() ContainerOption {
	return func(c *Container) {
		c.borderStyle = lipgloss.DoubleBorder()
	}
}

// WithFocused sets the focused state
func WithFocused(focused bool) ContainerOption {
	return func(c *Container) {
		c.focused = focused
	}
}

// WithTitle sets the container title
func WithTitle(title string) ContainerOption {
	return func(c *Container) {
		c.title = title
	}
}

// WithSize sets the container size
func WithSize(width, height int) ContainerOption {
	return func(c *Container) {
		c.width = width
		c.height = height
	}
}

// Render renders content inside the container
func (c *Container) Render(content string) string {
	t := theme.Current()

	borderColor := t.Border()
	if c.focused {
		borderColor = t.BorderFocused()
	}

	style := lipgloss.NewStyle().
		Padding(c.paddingTop, c.paddingRight, c.paddingBottom, c.paddingLeft)

	if c.borderTop || c.borderRight || c.borderBottom || c.borderLeft {
		style = style.
			Border(c.borderStyle, c.borderTop, c.borderRight, c.borderBottom, c.borderLeft).
			BorderForeground(borderColor)
	}

	if c.width > 0 {
		style = style.Width(c.width)
	}
	if c.height > 0 {
		style = style.Height(c.height)
	}

	result := style.Render(content)

	// Add title if present
	if c.title != "" && c.borderTop {
		result = c.addTitle(result, borderColor)
	}

	return result
}

// addTitle adds a title to the top border
func (c *Container) addTitle(content string, _ lipgloss.AdaptiveColor) string {
	lines := strings.Split(content, "\n")
	if len(lines) == 0 {
		return content
	}

	t := theme.Current()
	titleStyle := lipgloss.NewStyle().
		Foreground(t.Accent()).
		Bold(true)

	title := " " + c.title + " "
	styledTitle := titleStyle.Render(title)

	// Replace part of the first line with the title
	firstLine := lines[0]
	if len(firstLine) > 4 {
		// Insert title after the corner
		runes := []rune(firstLine)
		insertPos := 2
		if insertPos+len([]rune(title)) < len(runes)-2 {
			lines[0] = string(runes[:insertPos]) + styledTitle + string(runes[insertPos+len([]rune(title)):])
		}
	}

	return strings.Join(lines, "\n")
}
