package tui

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/XavierAgostino/macstrap/internal/engine"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// screen identifies which view is on top.
type screen int

const (
	screenDashboard screen = iota
	screenDoctor
	screenReport
	screenSecurity
	screenApps
	screenCLI
)

// menuItem is one action on the dashboard.
type menuItem struct {
	key   string // subcommand / screen id
	title string
	desc  string
}

var menu = []menuItem{
	{"doctor", "Doctor", "Check your environment health"},
	{"apps", "Apps", "Pick GUI apps to install"},
	{"cli", "CLI", "Pick optional developer CLIs"},
	{"report", "Report", "See what macstrap manages"},
	{"security", "Security", "Review your security posture"},
	{"install", "Install", "Run the full setup (dry-run first)"},
}

// model is the root Bubble Tea model. It owns the engine and the active screen;
// each screen renders values the engine decoded from the shell contracts.
type model struct {
	eng    *engine.Engine
	screen screen

	width, height int
	cursor        int // dashboard menu cursor

	report   *engine.Report
	doctor   *engine.Doctor
	security *engine.Security
	pk       *picker // active app/cli multi-select, nil otherwise

	loading bool
	err     error
}

// Run starts the TUI. It blocks until the user quits.
func Run(eng *engine.Engine) error {
	m := model{eng: eng}
	_, err := tea.NewProgram(m, tea.WithAltScreen()).Run()
	return err
}

func (m model) Init() tea.Cmd {
	return loadReport(m.eng)
}

// --- messages ---

type reportMsg struct{ r *engine.Report }
type doctorMsg struct{ d *engine.Doctor }
type securityMsg struct{ s *engine.Security }
type catalogMsg struct {
	kind string
	c    *engine.Catalog
}
type errMsg struct{ err error }

func (e errMsg) Error() string { return e.err.Error() }

// --- commands ---

func loadReport(eng *engine.Engine) tea.Cmd {
	return func() tea.Msg {
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		r, err := eng.Report(ctx)
		if err != nil {
			return errMsg{err}
		}
		return reportMsg{r}
	}
}

func loadDoctor(eng *engine.Engine) tea.Cmd {
	return func() tea.Msg {
		ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
		defer cancel()
		d, err := eng.Doctor(ctx)
		if err != nil {
			return errMsg{err}
		}
		return doctorMsg{d}
	}
}

func loadSecurity(eng *engine.Engine) tea.Cmd {
	return func() tea.Msg {
		ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
		defer cancel()
		s, err := eng.Security(ctx)
		if err != nil {
			return errMsg{err}
		}
		return securityMsg{s}
	}
}

func loadCatalog(eng *engine.Engine, kind string) tea.Cmd {
	return func() tea.Msg {
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		var (
			c   *engine.Catalog
			err error
		)
		if kind == "cli" {
			c, err = eng.CLICatalog(ctx)
		} else {
			c, err = eng.AppsCatalog(ctx)
		}
		if err != nil {
			return errMsg{err}
		}
		return catalogMsg{kind: kind, c: c}
	}
}

// runShell suspends the TUI and hands control to the bash entrypoint. This is
// how the app defers real work (install, app/cli install) to the scripts.
func runShell(eng *engine.Engine, args ...string) tea.Cmd {
	c := execCommand(eng, args...)
	return tea.ExecProcess(c, func(err error) tea.Msg {
		if err != nil {
			return errMsg{err}
		}
		return reloadMsg{}
	})
}

type reloadMsg struct{}

// --- update ---

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
		return m, nil

	case reportMsg:
		m.report = msg.r
		m.loading = false
		return m, nil
	case doctorMsg:
		m.doctor = msg.d
		m.loading = false
		return m, nil
	case securityMsg:
		m.security = msg.s
		m.loading = false
		return m, nil
	case catalogMsg:
		m.pk = newPicker(msg.kind, msg.c)
		m.loading = false
		return m, nil
	case reloadMsg:
		// After the shell hands control back, return home and refresh the summary.
		m.screen = screenDashboard
		m.pk = nil
		return m, loadReport(m.eng)
	case errMsg:
		m.err = msg.err
		m.loading = false
		return m, nil

	case tea.KeyMsg:
		return m.handleKey(msg)
	}
	return m, nil
}

func (m model) handleKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	// Global keys.
	switch msg.String() {
	case "ctrl+c":
		return m, tea.Quit
	}

	// Picker screens have their own keymap (space toggles, enter installs).
	if (m.screen == screenApps || m.screen == screenCLI) && m.pk != nil {
		return m.handlePickerKey(msg)
	}

	if m.screen != screenDashboard {
		// Detail screens: esc/backspace return home.
		switch msg.String() {
		case "esc", "backspace", "q", "left", "h":
			m.screen = screenDashboard
			m.err = nil
		}
		return m, nil
	}

	// Dashboard keys.
	switch msg.String() {
	case "q":
		return m, tea.Quit
	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
		}
	case "down", "j":
		if m.cursor < len(menu)-1 {
			m.cursor++
		}
	case "enter", "right", "l":
		return m.activate(menu[m.cursor].key)
	}
	return m, nil
}

// activate handles selecting a dashboard item.
func (m model) activate(key string) (tea.Model, tea.Cmd) {
	m.err = nil
	switch key {
	case "doctor":
		m.screen = screenDoctor
		m.loading = true
		return m, loadDoctor(m.eng)
	case "report":
		m.screen = screenReport
		m.loading = true
		return m, loadReport(m.eng)
	case "security":
		m.screen = screenSecurity
		m.loading = true
		return m, loadSecurity(m.eng)
	case "apps":
		m.screen = screenApps
		m.pk = nil
		m.loading = true
		return m, loadCatalog(m.eng, "apps")
	case "cli":
		m.screen = screenCLI
		m.pk = nil
		m.loading = true
		return m, loadCatalog(m.eng, "cli")
	case "install":
		return m, runShell(m.eng, "install", "--dry-run")
	}
	return m, nil
}

// handlePickerKey drives an app/cli multi-select. Confirming hands the chosen
// keys to the shell installer; the TUI performs no installation itself.
func (m model) handlePickerKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "esc", "backspace", "left", "h", "q":
		m.screen = screenDashboard
		m.pk = nil
		m.err = nil
	case "up", "k":
		m.pk.up()
	case "down", "j":
		m.pk.down()
	case " ", "x":
		m.pk.toggle()
	case "d":
		if sel := m.pk.selection(); sel != "" {
			return m, runShell(m.eng, m.pk.kind, sel, "--dry-run")
		}
	case "enter":
		if sel := m.pk.selection(); sel != "" {
			return m, runShell(m.eng, m.pk.kind, sel)
		}
	}
	return m, nil
}

// --- view ---

func (m model) View() string {
	switch m.screen {
	case screenDoctor:
		return m.frame("Doctor", m.viewDoctor())
	case screenReport:
		return m.frame("Report", m.viewReport())
	case screenSecurity:
		return m.frame("Security", m.viewSecurity())
	case screenApps:
		return m.frame("Apps", m.viewPicker())
	case screenCLI:
		return m.frame("CLI", m.viewPicker())
	default:
		return m.frame("macstrap", m.viewDashboard())
	}
}

func (m model) viewPicker() string {
	if m.loading || m.pk == nil {
		return styleSubtle.Render("loading catalog…")
	}
	return m.pk.view()
}

// frame wraps body content with a title header and a help footer.
func (m model) frame(title, body string) string {
	head := styleTitle.Render("macstrap") + styleSubtle.Render("  ·  "+title)
	var help string
	switch m.screen {
	case screenDashboard:
		help = styleHelp.Render("↑/↓ move · enter select · q quit")
	case screenApps, screenCLI:
		help = styleHelp.Render("↑/↓ move · space toggle · enter install · d preview · esc back")
	default:
		help = styleHelp.Render("esc back · ctrl+c quit")
	}
	if m.err != nil {
		body = styleErr.Render("error: "+m.err.Error()) + "\n\n" + body
	}
	return lipgloss.JoinVertical(lipgloss.Left, head, "", body, "", help)
}

func (m model) viewDashboard() string {
	var b strings.Builder
	for i, it := range menu {
		cursor := "  "
		title := styleBody.Render(it.title)
		if i == m.cursor {
			cursor = styleCursor.Render("▸ ")
			title = styleCursor.Render(it.title)
		}
		fmt.Fprintf(&b, "%s%-10s %s\n", cursor, title, styleSubtle.Render(it.desc))
	}
	b.WriteString("\n")
	b.WriteString(m.dashboardSummary())
	return b.String()
}

// dashboardSummary is a one-line at-a-glance of the machine, from the report.
func (m model) dashboardSummary() string {
	if m.report == nil {
		return styleSubtle.Render("loading machine summary…")
	}
	r := m.report
	parts := []string{
		fmt.Sprintf("profile %s", styleBody.Render(r.Profile)),
		fmt.Sprintf("%d core + %d apps", r.Homebrew.Core, r.Homebrew.Apps),
		fmt.Sprintf("%d dotfiles", r.DotfilesCount),
		fmt.Sprintf("%d optional CLIs", len(r.CLI)),
	}
	return styleSubtle.Render(strings.Join(parts, "  ·  "))
}

func (m model) viewDoctor() string {
	if m.loading || m.doctor == nil {
		return styleSubtle.Render("running checks…")
	}
	d := m.doctor
	var b strings.Builder
	summary := fmt.Sprintf("%s  %s ok · %s warn · %s error",
		levelStyle(d.Overall).Render(strings.ToUpper(d.Overall)),
		styleOK.Render(fmt.Sprint(d.Summary.OK)),
		styleWarn.Render(fmt.Sprint(d.Summary.Warn)),
		styleErr.Render(fmt.Sprint(d.Summary.Error)),
	)
	b.WriteString(summary + "\n\n")

	group := ""
	for _, c := range d.Checks {
		if c.Group != group {
			group = c.Group
			b.WriteString(styleGroup.Render(group) + "\n")
		}
		line := fmt.Sprintf("  %s %-18s %s",
			levelStyle(c.Level).Render(glyph(c.Level)),
			styleBody.Render(c.Label),
			levelStyle(c.Level).Render(c.Status),
		)
		if c.Hint != "" {
			line += styleSubtle.Render("  — " + c.Hint)
		}
		b.WriteString(line + "\n")
	}
	return b.String()
}

func (m model) viewReport() string {
	if m.loading || m.report == nil {
		return styleSubtle.Render("reading state…")
	}
	r := m.report
	var b strings.Builder
	fmt.Fprintf(&b, "%s %s\n", styleSubtle.Render("profile"), styleBody.Render(r.Profile))
	fmt.Fprintf(&b, "%s %d core, %d apps\n", styleSubtle.Render("homebrew"), r.Homebrew.Core, r.Homebrew.Apps)
	fmt.Fprintf(&b, "%s %d managed\n", styleSubtle.Render("dotfiles"), r.DotfilesCount)
	b.WriteString("\n")
	b.WriteString(styleGroup.Render("Optional CLIs") + "\n")
	if len(r.CLI) == 0 {
		b.WriteString(styleSubtle.Render("  none recorded — add some from the CLI screen\n"))
	}
	for _, c := range r.CLI {
		level := "ok"
		if c.Status != "installed" {
			level = "warn"
		}
		fmt.Fprintf(&b, "  %s %-14s %s\n",
			levelStyle(level).Render(glyph(level)),
			c.Key,
			styleSubtle.Render(c.Status),
		)
	}
	return b.String()
}

func (m model) viewSecurity() string {
	if m.loading || m.security == nil {
		return styleSubtle.Render("checking posture…")
	}
	s := m.security
	var b strings.Builder
	b.WriteString(levelStyle(s.Overall).Render(strings.ToUpper(s.Overall)) + "\n\n")
	for _, c := range s.Checks {
		fmt.Fprintf(&b, "  %s %-22s %s\n",
			levelStyle(c.Level).Render(glyph(c.Level)),
			styleBody.Render(c.Label),
			levelStyle(c.Level).Render(c.Detail),
		)
	}
	return b.String()
}
