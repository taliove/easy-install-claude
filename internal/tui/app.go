// Package tui provides the terminal user interface
package tui

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/spinner"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/taliove/go-install-claude/internal/config"
	"github.com/taliove/go-install-claude/internal/detector"
	"github.com/taliove/go-install-claude/internal/installer"
	"github.com/taliove/go-install-claude/internal/tui/components/core"
	"github.com/taliove/go-install-claude/internal/tui/components/dialog"
	"github.com/taliove/go-install-claude/internal/tui/components/wizard"
	"github.com/taliove/go-install-claude/internal/tui/styles"
	"github.com/taliove/go-install-claude/internal/tui/theme"
)

// Stage represents the current installation stage
type Stage int

const (
	StageWelcome Stage = iota
	StageDetecting
	StageInputKey
	StageSelectModel
	StageConfirm
	StageInstalling
	StageComplete
	StageError
	// 模型切换模式专用
	StageSwitchModel
	StageSwitchComplete
)

// AppMode 应用模式
type AppMode int

const (
	ModeFullInstall AppMode = iota // 完整安装模式
	ModeSwitchModel                // 模型切换模式
)

// Model is the main TUI model
type Model struct {
	mode   AppMode
	stage  Stage
	width  int
	height int

	// Components
	keyInput textinput.Model
	spinner  spinner.Model
	steps    *wizard.Steps
	selector *wizard.Selector

	// Data
	systemInfo  *detector.SystemInfo
	installCfg  *config.InstallConfig
	selectedIdx int

	// 模型切换模式的数据
	claudeDir    string // Claude 配置目录
	currentModel string // 当前模型

	// Installation state
	installResult *installer.Result
	errorMessage  string
	errorDetail   string

	// UI state
	showHelp bool
}

// Messages
type detectDoneMsg struct {
	info *detector.SystemInfo
	err  error
}

type installDoneMsg struct {
	result *installer.Result
}

type configWriteDoneMsg struct {
	err error
}

type modelUpdateDoneMsg struct {
	err error
}

// NewModel creates a new TUI model for full installation
func NewModel() Model {
	return newModel(ModeFullInstall, "", "")
}

// NewSwitchModelModel creates a new TUI model for switching models only
func NewSwitchModelModel(claudeDir string, currentModel string) Model {
	return newModel(ModeSwitchModel, claudeDir, currentModel)
}

// newModel creates a new TUI model with the specified mode
func newModel(mode AppMode, claudeDir string, currentModel string) Model {
	// Initialize text input
	ti := textinput.New()
	ti.Placeholder = "请输入您的万界 API Key"
	ti.Focus()
	ti.CharLimit = 128
	ti.Width = 40
	ti.EchoMode = textinput.EchoPassword
	ti.EchoCharacter = '•'

	// Initialize spinner
	sp := spinner.New()
	sp.Spinner = spinner.MiniDot
	sp.Style = lipgloss.NewStyle().Foreground(theme.Current().Primary())

	// Initialize steps based on mode
	var steps *wizard.Steps
	if mode == ModeSwitchModel {
		steps = wizard.SwitchModelSteps()
	} else {
		steps = wizard.DefaultSteps()
	}

	// Initialize model selector
	var selectorItems []wizard.SelectorItem
	for _, m := range config.SupportedModels {
		badge := ""
		if m.Default {
			badge = "⭐ 推荐"
		}
		// 标记当前选中的模型
		if m.ID == currentModel {
			badge = "✓ 当前"
		}
		selectorItems = append(selectorItems, wizard.SelectorItem{
			ID:          m.ID,
			Name:        m.Name,
			Description: m.Description,
			Badge:       badge,
		})
	}
	selector := wizard.NewSelector(selectorItems)
	selector.SetTitle(styles.IconPackage + " 选择模型")
	selector.SetWidth(50)

	// 设置默认选中的模型
	if currentModel != "" {
		for i, m := range config.SupportedModels {
			if m.ID == currentModel {
				selector.SetSelected(i)
				break
			}
		}
	}

	// 根据模式设置初始阶段
	initialStage := StageWelcome
	if mode == ModeSwitchModel {
		initialStage = StageSwitchModel
	}

	return Model{
		mode:         mode,
		stage:        initialStage,
		keyInput:     ti,
		spinner:      sp,
		steps:        steps,
		selector:     selector,
		installCfg:   config.NewDefaultConfig(),
		claudeDir:    claudeDir,
		currentModel: currentModel,
	}
}

// Init initializes the model
func (m Model) Init() tea.Cmd {
	return tea.Batch(
		textinput.Blink,
		m.spinner.Tick,
	)
}

// Update handles messages
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmds []tea.Cmd

	switch msg := msg.(type) {
	case tea.KeyMsg:
		// Handle help toggle
		if msg.String() == "?" && m.stage != StageInputKey {
			m.showHelp = !m.showHelp
			return m, nil
		}

		// Close help on any key
		if m.showHelp {
			m.showHelp = false
			return m, nil
		}

		switch msg.String() {
		case "ctrl+c", "q":
			if m.stage != StageInstalling {
				return m, tea.Quit
			}
		case "enter":
			return m.handleEnter()
		case "up", "k":
			if m.stage == StageSelectModel || m.stage == StageSwitchModel {
				m.selector.Prev()
			}
		case "down", "j":
			if m.stage == StageSelectModel || m.stage == StageSwitchModel {
				m.selector.Next()
			}
		case "esc":
			if m.stage == StageError {
				m.stage = StageWelcome
				m.errorMessage = ""
				m.errorDetail = ""
				m.steps = wizard.DefaultSteps()
			}
		}

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height

	case detectDoneMsg:
		if msg.err != nil {
			m.errorMessage = msg.err.Error()
			m.stage = StageError
			m.steps.Fail()
		} else {
			m.systemInfo = msg.info
			if msg.info.NeedsNodeJS() {
				m.errorMessage = "未检测到 Node.js 或 npm"
				m.errorDetail = "请先安装 Node.js 18+\n下载地址: https://nodejs.org/"
				m.stage = StageError
				m.steps.Fail()
			} else {
				m.steps.Complete()
				m.stage = StageInputKey
			}
		}

	case installDoneMsg:
		if msg.result.Success {
			m.installResult = msg.result
			m.steps.Complete()
			m.stage = StageComplete
		} else {
			m.errorMessage = "安装失败"
			m.errorDetail = msg.result.Error
			m.stage = StageError
			m.steps.Fail()
		}

	case configWriteDoneMsg:
		if msg.err != nil {
			m.errorMessage = "配置写入失败"
			m.errorDetail = msg.err.Error()
			m.stage = StageError
			m.steps.Fail()
		} else {
			return m, m.doInstall()
		}

	case modelUpdateDoneMsg:
		if msg.err != nil {
			m.errorMessage = "模型切换失败"
			m.errorDetail = msg.err.Error()
			m.stage = StageError
			m.steps.Fail()
		} else {
			m.steps.Complete()
			m.stage = StageSwitchComplete
		}

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		cmds = append(cmds, cmd)
	}

	// Update text input
	if m.stage == StageInputKey {
		var cmd tea.Cmd
		m.keyInput, cmd = m.keyInput.Update(msg)
		cmds = append(cmds, cmd)
	}

	return m, tea.Batch(cmds...)
}

// handleEnter handles the Enter key
func (m Model) handleEnter() (tea.Model, tea.Cmd) {
	switch m.stage {
	case StageWelcome:
		m.stage = StageDetecting
		return m, m.doDetect()

	case StageInputKey:
		key := strings.TrimSpace(m.keyInput.Value())
		if !config.ValidateAPIKey(key) {
			m.errorMessage = "API Key 格式不正确"
			return m, nil
		}
		m.installCfg.APIKey = key
		m.errorMessage = ""
		m.steps.Complete()
		m.stage = StageSelectModel

		// Find default model index
		for i, model := range config.SupportedModels {
			if model.Default {
				m.selector.SetSelected(i)
				break
			}
		}
		return m, nil

	case StageSelectModel:
		if item := m.selector.SelectedItem(); item != nil {
			m.installCfg.Model = item.ID
		}
		m.steps.Complete()
		m.stage = StageConfirm
		return m, nil

	case StageConfirm:
		m.steps.Complete()
		m.stage = StageInstalling
		return m, m.doWriteConfig()

	case StageComplete:
		return m, tea.Quit

	case StageError:
		return m, tea.Quit

	// 模型切换模式
	case StageSwitchModel:
		if item := m.selector.SelectedItem(); item != nil {
			m.installCfg.Model = item.ID
		}
		// 直接更新模型配置
		return m, m.doUpdateModel()

	case StageSwitchComplete:
		return m, tea.Quit
	}

	return m, nil
}

// doDetect performs environment detection
func (m Model) doDetect() tea.Cmd {
	return func() tea.Msg {
		info, err := detector.Detect()
		return detectDoneMsg{info: info, err: err}
	}
}

// doWriteConfig writes the configuration
func (m Model) doWriteConfig() tea.Cmd {
	return func() tea.Msg {
		err := m.installCfg.WriteSettings(m.systemInfo.ClaudeDir)
		return configWriteDoneMsg{err: err}
	}
}

// doInstall performs the installation
func (m Model) doInstall() tea.Cmd {
	return func() tea.Msg {
		inst := installer.NewInstaller()
		result := inst.Install()
		return installDoneMsg{result: result}
	}
}

// doUpdateModel updates only the model setting
func (m Model) doUpdateModel() tea.Cmd {
	return func() tea.Msg {
		err := config.UpdateModel(m.claudeDir, m.installCfg.Model)
		return modelUpdateDoneMsg{err: err}
	}
}

// View renders the UI
func (m Model) View() string {
	var content string

	switch m.stage {
	case StageWelcome:
		content = m.viewWelcome()
	case StageDetecting:
		content = m.viewDetecting()
	case StageInputKey:
		content = m.viewInputKey()
	case StageSelectModel:
		content = m.viewSelectModel()
	case StageConfirm:
		content = m.viewConfirm()
	case StageInstalling:
		content = m.viewInstalling()
	case StageComplete:
		content = m.viewComplete()
	case StageError:
		content = m.viewError()
	// 模型切换模式
	case StageSwitchModel:
		content = m.viewSwitchModel()
	case StageSwitchComplete:
		content = m.viewSwitchComplete()
	}

	// Add help overlay if showing
	if m.showHelp {
		helpDialog := dialog.NewHelpDialog()
		helpContent := helpDialog.Render()

		// Center overlay
		background := lipgloss.Place(m.width, m.height, lipgloss.Center, lipgloss.Center, content)
		helpWidth := lipgloss.Width(helpContent)
		helpHeight := lipgloss.Height(helpContent)
		x := (m.width - helpWidth) / 2
		y := (m.height - helpHeight) / 2

		return placeOverlayOn(x, y, helpContent, background)
	}

	// Center content
	return lipgloss.Place(m.width, m.height, lipgloss.Center, lipgloss.Center, content)
}

// placeOverlayOn places content at x,y on background
func placeOverlayOn(x, y int, overlay, background string) string {
	bgLines := strings.Split(background, "\n")
	overlayLines := strings.Split(overlay, "\n")

	for i, overlayLine := range overlayLines {
		bgY := y + i
		if bgY >= 0 && bgY < len(bgLines) {
			bgLine := bgLines[bgY]
			bgRunes := []rune(bgLine)

			// Pad if needed
			for len(bgRunes) < x {
				bgRunes = append(bgRunes, ' ')
			}

			// Insert overlay
			overlayRunes := []rune(overlayLine)
			newLine := string(bgRunes[:x]) + string(overlayRunes)
			if x+len(overlayRunes) < len(bgRunes) {
				newLine += string(bgRunes[x+len(overlayRunes):])
			}
			bgLines[bgY] = newLine
		}
	}

	return strings.Join(bgLines, "\n")
}

// viewWelcome renders the welcome screen
func (m Model) viewWelcome() string {
	t := theme.Current()
	var b strings.Builder

	// Logo
	b.WriteString(core.RenderSimpleLogo())
	b.WriteString("\n\n")

	// Welcome message
	normalStyle := lipgloss.NewStyle().Foreground(t.Text())
	b.WriteString(normalStyle.Render("欢迎使用 Claude Code 一键安装工具！"))
	b.WriteString("\n\n")

	// Features
	infoStyle := lipgloss.NewStyle().Foreground(t.Info())
	dimStyle := lipgloss.NewStyle().Foreground(t.TextDim())

	b.WriteString(infoStyle.Render("本工具将帮助您："))
	b.WriteString("\n")
	b.WriteString(dimStyle.Render(fmt.Sprintf("  %s 自动配置万界数据代理", styles.IconBullet)))
	b.WriteString("\n")
	b.WriteString(dimStyle.Render(fmt.Sprintf("  %s 安装 Claude Code CLI", styles.IconBullet)))
	b.WriteString("\n")
	b.WriteString(dimStyle.Render(fmt.Sprintf("  %s 配置 API Key 和模型", styles.IconBullet)))
	b.WriteString("\n\n")

	// Help
	helpStyle := lipgloss.NewStyle().Foreground(t.TextDim())
	b.WriteString(helpStyle.Render("按 Enter 开始安装 • 按 ? 查看帮助 • 按 q 退出"))

	return b.String()
}

// viewDetecting renders the detection screen
func (m Model) viewDetecting() string {
	t := theme.Current()
	var b strings.Builder

	// Steps
	b.WriteString(m.steps.Render())
	b.WriteString("\n\n")

	// Title
	titleStyle := lipgloss.NewStyle().Foreground(t.Primary()).Bold(true)
	b.WriteString(titleStyle.Render(styles.IconGear + " 环境检测"))
	b.WriteString("\n\n")

	// Spinner
	b.WriteString(fmt.Sprintf("%s 正在检测系统环境...", m.spinner.View()))
	b.WriteString("\n\n")

	dimStyle := lipgloss.NewStyle().Foreground(t.TextDim())
	b.WriteString(dimStyle.Render("检查 Node.js、npm、网络连接..."))

	return b.String()
}

// viewInputKey renders the API key input screen
func (m Model) viewInputKey() string {
	t := theme.Current()
	var b strings.Builder

	// Steps
	b.WriteString(m.steps.Render())
	b.WriteString("\n\n")

	// Title
	titleStyle := lipgloss.NewStyle().Foreground(t.Primary()).Bold(true)
	b.WriteString(titleStyle.Render(styles.IconKey + " 输入 API Key"))
	b.WriteString("\n\n")

	// System info
	if m.systemInfo != nil {
		b.WriteString(wizard.SystemInfoCard(
			m.systemInfo.GetOSName(),
			m.systemInfo.NodeVersion,
			m.systemInfo.NPMVersion,
			m.systemInfo.CanReachAPI,
		))
		b.WriteString("\n\n")
	}

	// Input prompt
	normalStyle := lipgloss.NewStyle().Foreground(t.Text())
	b.WriteString(normalStyle.Render("请输入您的万界数据 API Key："))
	b.WriteString("\n\n")

	// Input field
	b.WriteString("  > ")
	b.WriteString(m.keyInput.View())
	b.WriteString("\n\n")

	// Error message
	if m.errorMessage != "" {
		errorStyle := lipgloss.NewStyle().Foreground(t.Error())
		b.WriteString(errorStyle.Render(styles.IconError + " " + m.errorMessage))
		b.WriteString("\n\n")
	}

	// Help
	helpStyle := lipgloss.NewStyle().Foreground(t.TextDim())
	b.WriteString(helpStyle.Render("获取 Key: https://www.wanjiedata.com"))
	b.WriteString("\n")
	b.WriteString(helpStyle.Render("按 Enter 继续 • 按 q 退出"))

	return b.String()
}

// viewSelectModel renders the model selection screen
func (m Model) viewSelectModel() string {
	var b strings.Builder

	// Steps
	b.WriteString(m.steps.Render())
	b.WriteString("\n\n")

	// Selector
	b.WriteString(m.selector.Render())
	b.WriteString("\n")

	// Help
	t := theme.Current()
	helpStyle := lipgloss.NewStyle().Foreground(t.TextDim())
	b.WriteString(helpStyle.Render("↑/↓ 选择 • Enter 确认 • q 退出"))

	return b.String()
}

// viewConfirm renders the confirmation screen
func (m Model) viewConfirm() string {
	t := theme.Current()
	var b strings.Builder

	// Steps
	b.WriteString(m.steps.Render())
	b.WriteString("\n\n")

	// Title
	titleStyle := lipgloss.NewStyle().Foreground(t.Primary()).Bold(true)
	b.WriteString(titleStyle.Render(styles.IconPackage + " 确认配置"))
	b.WriteString("\n\n")

	// Config card
	card := wizard.NewConfigCard("配置摘要")
	card.AddItem("代理服务", config.WanjieName, false)
	card.AddItem("API 地址", m.installCfg.BaseURL, false)
	card.AddItem("默认模型", m.installCfg.Model, false)
	card.AddItem("API Key", m.installCfg.APIKey, true)
	if m.systemInfo != nil {
		card.SetFooter("配置路径: " + m.systemInfo.GetSettingsPath())
	}
	b.WriteString(card.Render())
	b.WriteString("\n\n")

	// Help
	helpStyle := lipgloss.NewStyle().Foreground(t.TextDim())
	b.WriteString(helpStyle.Render("按 Enter 开始安装 • 按 q 退出"))

	return b.String()
}

// viewInstalling renders the installation screen
func (m Model) viewInstalling() string {
	t := theme.Current()
	var b strings.Builder

	// Steps
	b.WriteString(m.steps.Render())
	b.WriteString("\n\n")

	// Title
	titleStyle := lipgloss.NewStyle().Foreground(t.Primary()).Bold(true)
	b.WriteString(titleStyle.Render(styles.IconRocket + " 正在安装"))
	b.WriteString("\n\n")

	// Progress items
	items := []struct {
		label  string
		active bool
	}{
		{"配置 NPM 镜像", true},
		{"安装 @anthropic-ai/claude-code", true},
	}

	for _, item := range items {
		b.WriteString(fmt.Sprintf("%s %s...", m.spinner.View(), item.label))
		b.WriteString("\n")
	}

	b.WriteString("\n")
	dimStyle := lipgloss.NewStyle().Foreground(t.TextDim())
	b.WriteString(dimStyle.Render("请稍候，这可能需要几分钟..."))
	b.WriteString("\n")

	warningStyle := lipgloss.NewStyle().Foreground(t.Warning())
	b.WriteString(warningStyle.Render(styles.IconWarning + " 请勿关闭此窗口"))

	return b.String()
}

// viewComplete renders the completion screen
func (m Model) viewComplete() string {
	t := theme.Current()
	var b strings.Builder

	// Steps
	b.WriteString(m.steps.Render())
	b.WriteString("\n\n")

	// Success message
	successStyle := lipgloss.NewStyle().Foreground(t.Success()).Bold(true)
	b.WriteString(successStyle.Render(styles.IconCheck + " 安装完成！"))
	b.WriteString("\n\n")

	// Success card
	cardContent := `Claude Code 已成功安装并配置！

现在您可以在终端中运行:
  $ claude

开始使用 Claude Code 进行 AI 编程！`

	cardStyle := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(t.Success()).
		Padding(1, 2)
	b.WriteString(cardStyle.Render(cardContent))
	b.WriteString("\n\n")

	// Help
	helpStyle := lipgloss.NewStyle().Foreground(t.TextDim())
	b.WriteString(helpStyle.Render("按 Enter 或 q 退出"))

	return b.String()
}

// viewError renders the error screen
func (m Model) viewError() string {
	t := theme.Current()
	var b strings.Builder

	// Steps
	b.WriteString(m.steps.Render())
	b.WriteString("\n\n")

	// Error dialog
	errorContent := m.errorMessage
	if m.errorDetail != "" {
		errorContent += "\n\n" + m.errorDetail
	}

	errorDialog := dialog.Error("出错了", errorContent)
	b.WriteString(errorDialog.Render())
	b.WriteString("\n\n")

	// Help
	helpStyle := lipgloss.NewStyle().Foreground(t.TextDim())
	b.WriteString(helpStyle.Render("按 Esc 返回 • 按 q 退出"))

	return b.String()
}

// viewSwitchModel renders the model switch screen
func (m Model) viewSwitchModel() string {
	t := theme.Current()
	var b strings.Builder

	// Steps
	b.WriteString(m.steps.Render())
	b.WriteString("\n\n")

	// Title
	titleStyle := lipgloss.NewStyle().Foreground(t.Primary()).Bold(true)
	b.WriteString(titleStyle.Render(styles.IconPackage + " 切换模型"))
	b.WriteString("\n\n")

	// Current model info
	if m.currentModel != "" {
		dimStyle := lipgloss.NewStyle().Foreground(t.TextDim())
		b.WriteString(dimStyle.Render(fmt.Sprintf("当前模型: %s", m.currentModel)))
		b.WriteString("\n\n")
	}

	// Selector
	b.WriteString(m.selector.Render())
	b.WriteString("\n")

	// Help
	helpStyle := lipgloss.NewStyle().Foreground(t.TextDim())
	b.WriteString(helpStyle.Render("↑/↓ 选择 • Enter 确认切换 • q 退出"))

	return b.String()
}

// viewSwitchComplete renders the switch complete screen
func (m Model) viewSwitchComplete() string {
	t := theme.Current()
	var b strings.Builder

	// Steps
	b.WriteString(m.steps.Render())
	b.WriteString("\n\n")

	// Success message
	successStyle := lipgloss.NewStyle().Foreground(t.Success()).Bold(true)
	b.WriteString(successStyle.Render(styles.IconCheck + " 模型切换成功！"))
	b.WriteString("\n\n")

	// Model info
	modelInfo := config.GetModelByID(m.installCfg.Model)
	modelName := m.installCfg.Model
	modelDesc := ""
	if modelInfo != nil {
		modelName = modelInfo.Name
		modelDesc = modelInfo.Description
	}

	cardContent := fmt.Sprintf(`已切换到: %s
%s

配置已更新，重新运行 claude 即可使用新模型。`, modelName, modelDesc)

	cardStyle := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(t.Success()).
		Padding(1, 2)
	b.WriteString(cardStyle.Render(cardContent))
	b.WriteString("\n\n")

	// Help
	helpStyle := lipgloss.NewStyle().Foreground(t.TextDim())
	b.WriteString(helpStyle.Render("按 Enter 或 q 退出"))

	return b.String()
}
