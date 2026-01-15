# TUI 设计规范

本文档定义了 Claude Code 安装器的 TUI 设计规范和组件库使用指南。

## 目录结构

```
internal/tui/
├── app.go                    # 主应用模型
├── theme/                    # 主题系统
│   ├── theme.go             # 主题接口定义
│   ├── manager.go           # 主题管理器
│   ├── opencode.go          # OpenCode 风格主题
│   ├── catppuccin.go        # Catppuccin 主题
│   └── tokyonight.go        # Tokyo Night 主题
├── layout/                   # 布局系统
│   ├── container.go         # 容器组件
│   └── overlay.go           # 覆盖层/弹窗
├── styles/                   # 样式工具
│   ├── styles.go            # 样式助手函数
│   └── icons.go             # Unicode 图标库
└── components/              # UI 组件
    ├── core/
    │   ├── status.go        # 状态栏
    │   └── logo.go          # Logo 渲染
    ├── wizard/
    │   ├── steps.go         # 步骤指示器
    │   ├── selector.go      # 选择器
    │   ├── progress.go      # 进度显示
    │   └── config.go        # 配置卡片
    └── dialog/
        ├── dialog.go        # 对话框
        └── help.go          # 帮助对话框
```

## 主题系统

### 主题接口

每个主题必须实现 `Theme` 接口：

```go
type Theme interface {
    Name() string
    
    // 主色调
    Primary() lipgloss.AdaptiveColor
    Secondary() lipgloss.AdaptiveColor
    Accent() lipgloss.AdaptiveColor
    
    // 状态色
    Success() lipgloss.AdaptiveColor
    Error() lipgloss.AdaptiveColor
    Warning() lipgloss.AdaptiveColor
    Info() lipgloss.AdaptiveColor
    
    // 文本色
    Text() lipgloss.AdaptiveColor
    TextMuted() lipgloss.AdaptiveColor
    TextDim() lipgloss.AdaptiveColor
    
    // 背景色
    Background() lipgloss.AdaptiveColor
    BackgroundSecondary() lipgloss.AdaptiveColor
    BackgroundHighlight() lipgloss.AdaptiveColor
    
    // 边框色
    Border() lipgloss.AdaptiveColor
    BorderFocused() lipgloss.AdaptiveColor
    BorderDim() lipgloss.AdaptiveColor
}
```

### 自适应颜色

使用 `lipgloss.AdaptiveColor` 支持亮色/暗色终端：

```go
primary := lipgloss.AdaptiveColor{
    Dark:  "#00D4AA",  // 暗色终端使用
    Light: "#00A080",  // 亮色终端使用
}
```

### 使用主题

```go
import "github.com/taliove/go-install-claude/internal/tui/theme"

// 获取当前主题
t := theme.Current()

// 使用主题颜色
style := lipgloss.NewStyle().Foreground(t.Primary())

// 切换主题
theme.SetTheme("catppuccin")
```

## 颜色规范

### OpenCode 主题色板

| 用途 | 暗色模式 | 亮色模式 |
|------|----------|----------|
| Primary | `#00D4AA` | `#00A080` |
| Secondary | `#00A8E8` | `#0080B8` |
| Accent | `#00FFD4` | `#00D4AA` |
| Success | `#00D26A` | `#00A050` |
| Error | `#FF6B6B` | `#E05050` |
| Warning | `#FFD93D` | `#D4B030` |
| Info | `#4ECDC4` | `#3ABDB4` |
| Text | `#E8E8E8` | `#1A1A1A` |
| TextMuted | `#888888` | `#666666` |
| TextDim | `#555555` | `#999999` |
| Background | `#1A1B26` | `#FAFAFA` |

## 图标规范

### 状态图标

```go
const (
    IconCheck   = "✓"   // 成功/完成
    IconCross   = "✗"   // 失败
    IconError   = "✖"   // 错误
    IconWarning = "⚠"   // 警告
    IconInfo    = "ℹ"   // 信息
)
```

### 导航图标

```go
const (
    IconArrow      = "→"   // 箭头
    IconBullet     = "•"   // 列表项
    IconCircle     = "○"   // 空圆
    IconBox        = "☐"   // 复选框
    IconBoxChecked = "☑"   // 已选复选框
)
```

### 功能图标

```go
const (
    IconKey     = "🔑"   // 密钥
    IconPackage = "📦"   // 包/配置
    IconRocket  = "🚀"   // 启动/安装
    IconGear    = "⚙"    // 设置
)
```

### 进度条字符

```go
const (
    IconProgressFull  = "█"   // 已填充
    IconProgressEmpty = "░"   // 未填充
)
```

## 样式助手

### 基础样式

```go
import "github.com/taliove/go-install-claude/internal/tui/styles"

// 文本样式
styles.BaseStyle()      // 基础文本
styles.Bold()           // 粗体
styles.Muted()          // 次要文本
styles.Dim()            // 暗淡文本

// 颜色样式
styles.Primary()        // 主色调
styles.Accent()         // 强调色
styles.Success()        // 成功
styles.Error()          // 错误
styles.Warning()        // 警告
styles.Info()           // 信息
```

### 容器样式

```go
styles.Border()         // 带边框
styles.FocusedBorder()  // 聚焦边框
styles.Card()           // 卡片样式
styles.FocusedCard()    // 聚焦卡片
```

### 按钮样式

```go
styles.Button()         // 按钮
styles.ButtonDisabled() // 禁用按钮
styles.Badge()          // 徽章
styles.SuccessBadge()   // 成功徽章
styles.ErrorBadge()     // 错误徽章
```

## 组件使用

### 步骤指示器

```go
import "github.com/taliove/go-install-claude/internal/tui/components/wizard"

// 创建步骤
steps := wizard.NewSteps("检测", "密钥", "模型", "确认", "完成")

// 设置当前步骤
steps.SetCurrent(2)

// 完成当前步骤
steps.Complete()

// 渲染
output := steps.Render()
// 输出: ✓ 检测 → ✓ 密钥 → → 模型 → ○ 确认 → ○ 完成
```

### 选择器

```go
items := []wizard.SelectorItem{
    {ID: "model1", Name: "Claude Sonnet 4", Description: "推荐", Badge: "⭐"},
    {ID: "model2", Name: "Claude Opus 4", Description: "最强"},
}

selector := wizard.NewSelector(items)
selector.SetTitle("选择模型")

// 导航
selector.Next()
selector.Prev()

// 获取选中项
item := selector.SelectedItem()
```

### 进度显示

```go
progress := wizard.NewProgress(60)
progress.SetPhases("配置镜像", "下载", "安装", "验证")

// 更新状态
progress.SetPhaseStatus(1, wizard.PhaseRunning)
progress.SetPhasePercent(1, 50.0)

// 添加日志
progress.AddLog("正在下载 @anthropic-ai/claude-code...")

output := progress.Render()
```

### 配置卡片

```go
card := wizard.NewConfigCard("配置摘要")
card.AddItem("API 地址", "https://...", false)
card.AddItem("API Key", "sk-xxx...", true)  // masked
card.SetFooter("配置路径: ~/.claude/settings.json")

output := card.Render()
```

### 对话框

```go
import "github.com/taliove/go-install-claude/internal/tui/components/dialog"

// 快捷创建
errDialog := dialog.Error("出错了", "无法连接服务器")
confirmDialog := dialog.Confirm("确认", "是否继续?")
successDialog := dialog.Success("完成", "安装成功!")

// 自定义
d := dialog.NewDialog(dialog.DialogInfo, "标题", "内容")
d.WithButtons("确定", "取消")
d.WithWidth(50)
d.WithShadow(true)

output := d.Render()
```

## 布局规范

### 容器

```go
import "github.com/taliove/go-install-claude/internal/tui/layout"

container := layout.NewContainer(
    layout.WithPaddingAll(1),
    layout.WithBorderAll(),
    layout.WithRoundedBorder(),
    layout.WithTitle("标题"),
    layout.WithFocused(true),
)

output := container.Render(content)
```

### 覆盖层

```go
overlay := layout.NewOverlay(
    layout.WithShadow(true),
)

// 将对话框居中放置在背景上
output := overlay.Render(dialogContent, background, bgWidth, bgHeight)
```

## 键盘快捷键规范

| 按键 | 功能 |
|------|------|
| `Enter` | 确认/继续 |
| `Esc` | 返回/取消 |
| `↑/k` | 向上选择 |
| `↓/j` | 向下选择 |
| `q` | 退出程序 |
| `?` | 显示帮助 |

## 渲染最佳实践

### 1. 使用主题颜色

始终通过主题获取颜色，不要硬编码：

```go
// ✅ 正确
t := theme.Current()
style := lipgloss.NewStyle().Foreground(t.Primary())

// ❌ 错误
style := lipgloss.NewStyle().Foreground(lipgloss.Color("#00D4AA"))
```

### 2. 使用样式助手

使用预定义的样式助手保持一致性：

```go
// ✅ 正确
text := styles.Success().Render("成功")

// ❌ 不推荐
text := lipgloss.NewStyle().Foreground(t.Success()).Render("成功")
```

### 3. 响应式布局

考虑终端大小变化：

```go
func (m Model) View() string {
    // 根据宽度调整布局
    if m.width < 60 {
        return m.viewCompact()
    }
    return m.viewFull()
}
```

### 4. 状态管理

清晰的状态管理：

```go
type Stage int

const (
    StageWelcome Stage = iota
    StageDetecting
    StageInputKey
    StageSelectModel
    // ...
)
```

## 添加新主题

1. 在 `internal/tui/theme/` 创建新文件：

```go
// mytheme.go
package theme

import "github.com/charmbracelet/lipgloss"

func NewMyTheme() Theme {
    return &BaseTheme{
        name: "mytheme",
        primary: lipgloss.AdaptiveColor{Dark: "#...", Light: "#..."},
        // ... 其他颜色
    }
}
```

2. 在 `manager.go` 中注册：

```go
func init() {
    RegisterTheme("mytheme", NewMyTheme())
}
```

## 添加新组件

1. 在适当的目录创建组件文件
2. 遵循现有组件的模式
3. 使用主题颜色和样式助手
4. 提供 `Render()` 方法返回字符串
5. 在文档中添加使用说明
