package wizard

import (
	"strings"

	"github.com/charmbracelet/lipgloss"

	"github.com/taliove/go-install-claude/internal/tui/styles"
	"github.com/taliove/go-install-claude/internal/tui/theme"
)

// Step represents a wizard step
type Step struct {
	Name   string
	Status StepStatus
	Icon   string
}

// StepStatus represents the status of a step
type StepStatus int

const (
	StepPending StepStatus = iota
	StepCurrent
	StepCompleted
	StepFailed
)

// Steps represents the step indicator component
type Steps struct {
	steps   []Step
	current int
}

// NewSteps creates a new step indicator
func NewSteps(stepNames ...string) *Steps {
	steps := make([]Step, len(stepNames))
	for i, name := range stepNames {
		steps[i] = Step{
			Name:   name,
			Status: StepPending,
		}
	}
	if len(steps) > 0 {
		steps[0].Status = StepCurrent
	}
	return &Steps{
		steps:   steps,
		current: 0,
	}
}

// DefaultSteps creates steps for the installer wizard
func DefaultSteps() *Steps {
	return NewSteps("检测", "密钥", "模型", "确认", "安装", "完成")
}

// SwitchModelSteps creates steps for the model switch wizard
func SwitchModelSteps() *Steps {
	return NewSteps("选择模型", "完成")
}

// SetCurrent sets the current step
func (s *Steps) SetCurrent(index int) {
	if index < 0 || index >= len(s.steps) {
		return
	}

	for i := range s.steps {
		switch {
		case i < index:
			s.steps[i].Status = StepCompleted
		case i == index:
			s.steps[i].Status = StepCurrent
		default:
			s.steps[i].Status = StepPending
		}
	}
	s.current = index
}

// Complete marks the current step as complete and moves to next
func (s *Steps) Complete() {
	if s.current < len(s.steps) {
		s.steps[s.current].Status = StepCompleted
		if s.current < len(s.steps)-1 {
			s.current++
			s.steps[s.current].Status = StepCurrent
		}
	}
}

// Fail marks the current step as failed
func (s *Steps) Fail() {
	if s.current < len(s.steps) {
		s.steps[s.current].Status = StepFailed
	}
}

// Current returns the current step index
func (s *Steps) Current() int {
	return s.current
}

// Render renders the step indicator
func (s *Steps) Render() string {
	t := theme.Current()

	var parts []string

	for i, step := range s.steps {
		var icon string
		var style lipgloss.Style

		switch step.Status {
		case StepCompleted:
			icon = styles.IconCheck
			style = lipgloss.NewStyle().Foreground(t.Success())
		case StepCurrent:
			icon = styles.IconArrow
			style = lipgloss.NewStyle().Foreground(t.Accent()).Bold(true)
		case StepFailed:
			icon = styles.IconCross
			style = lipgloss.NewStyle().Foreground(t.Error())
		default:
			icon = styles.IconCircle
			style = lipgloss.NewStyle().Foreground(t.TextDim())
		}

		// Custom icon override
		if step.Icon != "" {
			icon = step.Icon
		}

		stepText := style.Render(icon + " " + step.Name)
		parts = append(parts, stepText)

		// Add arrow separator (except for last item)
		if i < len(s.steps)-1 {
			sepStyle := lipgloss.NewStyle().Foreground(t.TextDim())
			parts = append(parts, sepStyle.Render(" → "))
		}
	}

	return strings.Join(parts, "")
}

// RenderVertical renders steps vertically
func (s *Steps) RenderVertical() string {
	t := theme.Current()

	var lines []string

	for i, step := range s.steps {
		var icon string
		var style lipgloss.Style
		var lineStyle lipgloss.Style

		switch step.Status {
		case StepCompleted:
			icon = styles.IconCheck
			style = lipgloss.NewStyle().Foreground(t.Success())
			lineStyle = lipgloss.NewStyle().Foreground(t.Success())
		case StepCurrent:
			icon = styles.IconArrow
			style = lipgloss.NewStyle().Foreground(t.Accent()).Bold(true)
			lineStyle = lipgloss.NewStyle().Foreground(t.TextDim())
		case StepFailed:
			icon = styles.IconCross
			style = lipgloss.NewStyle().Foreground(t.Error())
			lineStyle = lipgloss.NewStyle().Foreground(t.Error())
		default:
			icon = styles.IconCircle
			style = lipgloss.NewStyle().Foreground(t.TextDim())
			lineStyle = lipgloss.NewStyle().Foreground(t.TextDim())
		}

		stepText := style.Render("  " + icon + " " + step.Name)
		lines = append(lines, stepText)

		// Add connector line (except for last item)
		if i < len(s.steps)-1 {
			connector := lineStyle.Render("  │")
			lines = append(lines, connector)
		}
	}

	return strings.Join(lines, "\n")
}

// RenderCompact renders a compact step indicator
func (s *Steps) RenderCompact() string {
	t := theme.Current()

	current := s.current + 1
	total := len(s.steps)

	// Format: "步骤 2/5 - 密钥"
	numStyle := lipgloss.NewStyle().Foreground(t.Accent()).Bold(true)
	textStyle := lipgloss.NewStyle().Foreground(t.Text())

	stepName := ""
	if s.current < len(s.steps) {
		stepName = s.steps[s.current].Name
	}

	return textStyle.Render("步骤 ") +
		numStyle.Render(strings.Repeat("", 0)+string(rune('0'+current))+"/"+string(rune('0'+total))) +
		textStyle.Render(" - ") +
		numStyle.Render(stepName)
}
