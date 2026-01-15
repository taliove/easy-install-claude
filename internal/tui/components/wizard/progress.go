package wizard

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/taliove/go-install-claude/internal/tui/styles"
	"github.com/taliove/go-install-claude/internal/tui/theme"
)

// ProgressPhase represents a phase in the installation progress
type ProgressPhase struct {
	Name    string
	Status  PhaseStatus
	Message string
	Percent float64
}

// PhaseStatus represents the status of a progress phase
type PhaseStatus int

const (
	PhaseWaiting PhaseStatus = iota
	PhaseRunning
	PhaseComplete
	PhaseFailed
)

// Progress represents the installation progress component
type Progress struct {
	phases       []ProgressPhase
	currentPhase int
	width        int
	showPercent  bool
	logs         []string
	maxLogs      int
}

// NewProgress creates a new progress component
func NewProgress(width int) *Progress {
	return &Progress{
		phases:       make([]ProgressPhase, 0),
		currentPhase: 0,
		width:        width,
		showPercent:  true,
		logs:         make([]string, 0),
		maxLogs:      5,
	}
}

// SetPhases sets the progress phases
func (p *Progress) SetPhases(phases ...string) {
	p.phases = make([]ProgressPhase, len(phases))
	for i, name := range phases {
		status := PhaseWaiting
		if i == 0 {
			status = PhaseRunning
		}
		p.phases[i] = ProgressPhase{
			Name:   name,
			Status: status,
		}
	}
	p.currentPhase = 0
}

// DefaultPhases sets default installation phases
func (p *Progress) DefaultPhases() {
	p.SetPhases(
		"配置 NPM 镜像",
		"下载 Claude Code",
		"安装依赖",
		"验证安装",
	)
}

// SetPhaseStatus sets the status of a phase
func (p *Progress) SetPhaseStatus(index int, status PhaseStatus) {
	if index >= 0 && index < len(p.phases) {
		p.phases[index].Status = status
	}
}

// SetPhasePercent sets the percentage of a phase
func (p *Progress) SetPhasePercent(index int, percent float64) {
	if index >= 0 && index < len(p.phases) {
		p.phases[index].Percent = percent
	}
}

// SetPhaseMessage sets the message for a phase
func (p *Progress) SetPhaseMessage(index int, message string) {
	if index >= 0 && index < len(p.phases) {
		p.phases[index].Message = message
	}
}

// NextPhase advances to the next phase
func (p *Progress) NextPhase() {
	if p.currentPhase < len(p.phases) {
		p.phases[p.currentPhase].Status = PhaseComplete
		p.phases[p.currentPhase].Percent = 100

		if p.currentPhase < len(p.phases)-1 {
			p.currentPhase++
			p.phases[p.currentPhase].Status = PhaseRunning
		}
	}
}

// FailCurrent marks the current phase as failed
func (p *Progress) FailCurrent(message string) {
	if p.currentPhase < len(p.phases) {
		p.phases[p.currentPhase].Status = PhaseFailed
		p.phases[p.currentPhase].Message = message
	}
}

// AddLog adds a log message
func (p *Progress) AddLog(message string) {
	p.logs = append(p.logs, message)
	if len(p.logs) > p.maxLogs {
		p.logs = p.logs[len(p.logs)-p.maxLogs:]
	}
}

// Render renders the progress component
func (p *Progress) Render() string {
	t := theme.Current()

	var content strings.Builder

	// Title
	titleStyle := lipgloss.NewStyle().
		Foreground(t.Primary()).
		Bold(true)
	content.WriteString(titleStyle.Render("🚀 正在安装"))
	content.WriteString("\n\n")

	// Phases
	for _, phase := range p.phases {
		content.WriteString(p.renderPhase(phase))
		content.WriteString("\n")
	}

	// Logs
	if len(p.logs) > 0 {
		content.WriteString("\n")
		logStyle := lipgloss.NewStyle().Foreground(t.TextDim())
		for _, log := range p.logs {
			content.WriteString(logStyle.Render("  " + log))
			content.WriteString("\n")
		}
	}

	// Warning
	content.WriteString("\n")
	warningStyle := lipgloss.NewStyle().Foreground(t.Warning())
	content.WriteString(warningStyle.Render(styles.IconWarning + " 请勿关闭此窗口"))

	return content.String()
}

// renderPhase renders a single phase
func (p *Progress) renderPhase(phase ProgressPhase) string {
	t := theme.Current()

	var icon string
	var nameStyle lipgloss.Style
	var statusText string

	switch phase.Status {
	case PhaseComplete:
		icon = styles.IconCheck
		nameStyle = lipgloss.NewStyle().Foreground(t.Success())
		statusText = "完成"
	case PhaseRunning:
		icon = styles.IconSpinner0
		nameStyle = lipgloss.NewStyle().Foreground(t.Accent()).Bold(true)
		if phase.Percent > 0 {
			statusText = styles.RenderProgressBar(phase.Percent, 15)
		}
	case PhaseFailed:
		icon = styles.IconCross
		nameStyle = lipgloss.NewStyle().Foreground(t.Error())
		statusText = "失败"
	default:
		icon = styles.IconCircle
		nameStyle = lipgloss.NewStyle().Foreground(t.TextDim())
		statusText = "等待"
	}

	line := nameStyle.Render("  " + icon + " " + phase.Name)

	if statusText != "" {
		statusStyle := lipgloss.NewStyle().Foreground(t.TextMuted())
		line += statusStyle.Render("  " + statusText)
	}

	if phase.Message != "" {
		msgStyle := lipgloss.NewStyle().Foreground(t.TextDim())
		line += "\n" + msgStyle.Render("    "+phase.Message)
	}

	return line
}

// RenderSimple renders a simple progress bar
func RenderSimpleProgress(label string, percent float64, width int) string {
	t := theme.Current()

	labelStyle := lipgloss.NewStyle().Foreground(t.Text())
	barStyle := lipgloss.NewStyle().Foreground(t.Primary())
	percentStyle := lipgloss.NewStyle().Foreground(t.TextMuted())

	bar := styles.RenderProgressBar(percent, width-len(label)-10)

	return labelStyle.Render(label) + " " +
		barStyle.Render(bar) + " " +
		percentStyle.Render(strings.Repeat(" ", 3-len(string(rune(int(percent)))))+string(rune(int(percent)))+"%%")
}
