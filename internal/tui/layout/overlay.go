package layout

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/taliove/go-install-claude/internal/tui/theme"
)

// Overlay renders content as a centered overlay with optional shadow
type Overlay struct {
	width  int
	height int
	shadow bool
}

// OverlayOption is a function that modifies an Overlay
type OverlayOption func(*Overlay)

// NewOverlay creates a new overlay
func NewOverlay(opts ...OverlayOption) *Overlay {
	o := &Overlay{
		shadow: true,
	}
	for _, opt := range opts {
		opt(o)
	}
	return o
}

// WithOverlaySize sets the overlay size
func WithOverlaySize(width, height int) OverlayOption {
	return func(o *Overlay) {
		o.width = width
		o.height = height
	}
}

// WithShadow enables/disables shadow
func WithShadow(shadow bool) OverlayOption {
	return func(o *Overlay) {
		o.shadow = shadow
	}
}

// Render places the overlay content centered on the background
func (o *Overlay) Render(content, background string, bgWidth, bgHeight int) string {
	t := theme.Current()

	// Add shadow if enabled
	if o.shadow {
		content = o.addShadow(content)
	}

	// Get content dimensions
	contentLines := strings.Split(content, "\n")
	contentHeight := len(contentLines)
	contentWidth := 0
	for _, line := range contentLines {
		if w := lipgloss.Width(line); w > contentWidth {
			contentWidth = w
		}
	}

	// Calculate center position
	x := (bgWidth - contentWidth) / 2
	y := (bgHeight - contentHeight) / 2

	if x < 0 {
		x = 0
	}
	if y < 0 {
		y = 0
	}

	// Place overlay on background
	return placeOverlay(x, y, content, background, bgWidth, bgHeight, t.BackgroundSecondary())
}

// addShadow adds a drop shadow effect to the content
func (o *Overlay) addShadow(content string) string {
	t := theme.Current()
	lines := strings.Split(content, "\n")

	shadowStyle := lipgloss.NewStyle().
		Foreground(t.BackgroundSecondary())

	shadowChar := shadowStyle.Render("░")

	var result []string
	for _, line := range lines {
		// Add shadow to the right
		result = append(result, line+shadowChar+shadowChar)
	}

	// Add shadow at the bottom
	if len(lines) > 0 {
		width := lipgloss.Width(lines[0]) + 2
		bottomShadow := strings.Repeat(shadowChar, width)
		result = append(result, "  "+bottomShadow)
	}

	return strings.Join(result, "\n")
}

// placeOverlay places content at x,y position on background
func placeOverlay(x, y int, overlay, background string, bgWidth, bgHeight int, _ lipgloss.AdaptiveColor) string {
	bgLines := strings.Split(background, "\n")
	overlayLines := strings.Split(overlay, "\n")

	// Ensure background has enough lines
	for len(bgLines) < bgHeight {
		bgLines = append(bgLines, strings.Repeat(" ", bgWidth))
	}

	// Place overlay
	for i, overlayLine := range overlayLines {
		bgY := y + i
		if bgY >= 0 && bgY < len(bgLines) {
			bgLine := bgLines[bgY]
			// Ensure line is long enough
			for lipgloss.Width(bgLine) < x {
				bgLine += " "
			}

			// Split at x position and insert overlay
			bgRunes := []rune(bgLine)
			overlayWidth := lipgloss.Width(overlayLine)

			var newLine string
			if x < len(bgRunes) {
				newLine = string(bgRunes[:x]) + overlayLine
				if x+overlayWidth < len(bgRunes) {
					newLine += string(bgRunes[x+overlayWidth:])
				}
			} else {
				newLine = bgLine + strings.Repeat(" ", x-len(bgRunes)) + overlayLine
			}

			bgLines[bgY] = newLine
		}
	}

	return strings.Join(bgLines, "\n")
}

// Center centers content in the given dimensions
func Center(content string, width, height int) string {
	return lipgloss.Place(width, height, lipgloss.Center, lipgloss.Center, content)
}
