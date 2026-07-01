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
	screenLogs
	screenInstall
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
	{"logs", "Logs", "Browse logs from the last run"},
	{"install", "Install", "Preview the plan, then run setup"},
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
	pk       *picker      // active app/cli multi-select, nil otherwise
	lv       *logsView    // active logs browser, nil otherwise
	inst     *installView // active install plan stream, nil otherwise

	loading    bool
	spin       int  // spinner frame counter
	ticking    bool // a tick is already scheduled
	doctorBusy bool // a doctor run is in flight (avoid concurrent shell-outs)
	err        error
}

// Run starts the TUI. It blocks until the user quits.
func Run(eng *engine.Engine) error {
	m := model{eng: eng, doctorBusy: true} // Init launches the first doctor run
	_, err := tea.NewProgram(m, tea.WithAltScreen()).Run()
	return err
}

// Init warms the dashboard: the report for the status pane, doctor in the
// background for the health summary, and the spinner tick.
func (m model) Init() tea.Cmd {
	return tea.Batch(loadReport(m.eng), loadDoctor(m.eng), tick())
}

// --- messages ---

type reportMsg struct{ r *engine.Report }
type doctorMsg struct{ d *engine.Doctor }
type securityMsg struct{ s *engine.Security }
type catalogMsg struct {
	kind string
	c    *engine.Catalog
}
type logsMsg struct{ entries []engine.LogEntry }
type errMsg struct{ err error }
type tickMsg time.Time

func (e errMsg) Error() string { return e.err.Error() }

// --- commands ---

func tick() tea.Cmd {
	return tea.Tick(120*time.Millisecond, func(t time.Time) tea.Msg { return tickMsg(t) })
}

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

// loadLogs lists the captured step logs from the last quiet-mode run. It reads
// the filesystem directly (not a shell contract) but resolves the log dir the
// same way scripts/lib/ui.sh does, via engine.LogDir.
func loadLogs(eng *engine.Engine) tea.Cmd {
	return func() tea.Msg {
		entries, err := eng.Logs()
		if err != nil {
			return errMsg{err}
		}
		return logsMsg{entries}
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

// busy reports whether anything is animating, so the tick loop knows to keep
// running.
func (m model) busy() bool {
	if m.loading {
		return true
	}
	if m.inst != nil && !m.inst.done {
		return true
	}
	// Dashboard health summary still warming up.
	return m.screen == screenDashboard && (m.doctor == nil || m.report == nil)
}

// startTick schedules a spinner tick unless one is already pending.
func (m *model) startTick() tea.Cmd {
	if m.ticking {
		return nil
	}
	m.ticking = true
	return tick()
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
		if m.lv != nil {
			m.lv.setHeight(m.height)
		}
		return m, nil

	case tickMsg:
		m.ticking = false
		m.spin++
		if m.busy() {
			return m, m.startTick()
		}
		return m, nil

	case reportMsg:
		m.report = msg.r
		m.loading = false
		return m, nil
	case doctorMsg:
		m.doctor = msg.d
		m.doctorBusy = false
		m.loading = false
		return m, nil
	case securityMsg:
		m.security = msg.s
		m.loading = false
		return m, nil
	case catalogMsg:
		m.pk = newPicker(msg.kind, msg.c, m.report)
		m.loading = false
		return m, nil
	case logsMsg:
		m.lv = newLogsView(msg.entries)
		m.lv.setHeight(m.height)
		m.loading = false
		return m, nil
	case installLineMsg:
		if m.inst == nil {
			return m, nil
		}
		if m.inst.apply(msg.ev) {
			return m, m.inst.wait()
		}
		return m, nil
	case reloadMsg:
		// After the shell hands control back, return home and refresh both the
		// summary and the health check — the run may have changed either.
		m.screen = screenDashboard
		m.pk = nil
		m.inst = nil
		m.doctor = nil
		m.doctorBusy = true
		return m, tea.Batch(loadReport(m.eng), loadDoctor(m.eng), m.startTick())
	case errMsg:
		m.err = msg.err
		m.loading = false
		m.doctorBusy = false
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

	// Logs has a list/pager keymap of its own.
	if m.screen == screenLogs {
		return m.handleLogsKey(msg)
	}

	// Install: esc backs out; enter (once the plan is ready) runs for real.
	if m.screen == screenInstall {
		switch msg.String() {
		case "esc", "backspace", "left", "h", "q":
			m.screen = screenDashboard
			m.inst = nil
			m.err = nil
		case "enter":
			if m.inst != nil && m.inst.done && !m.inst.fail {
				return m, runShell(m.eng, "install")
			}
		}
		return m, nil
	}

	if m.screen != screenDashboard {
		// Detail screens: esc/backspace return home.
		switch msg.String() {
		case "esc", "backspace", "q", "left", "h":
			m.screen = screenDashboard
			m.err = nil
		case "r":
			// Re-run the screen's check in place.
			if m.screen == screenDoctor {
				m.doctor = nil // force a fresh run instead of the cached one
			}
			return m.activate(screenKey(m.screen))
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

// screenKey maps a detail screen back to its menu key (for the r = rerun key).
func screenKey(s screen) string {
	switch s {
	case screenDoctor:
		return "doctor"
	case screenReport:
		return "report"
	case screenSecurity:
		return "security"
	default:
		return ""
	}
}

// activate handles selecting a dashboard item.
func (m model) activate(key string) (tea.Model, tea.Cmd) {
	m.err = nil
	switch key {
	case "doctor":
		// Reuse the background run's result when we have it; r reruns.
		m.screen = screenDoctor
		if m.doctor != nil {
			return m, nil
		}
		m.loading = true
		if m.doctorBusy {
			return m, m.startTick() // a run is already in flight; just wait
		}
		m.doctorBusy = true
		return m, tea.Batch(loadDoctor(m.eng), m.startTick())
	case "report":
		m.screen = screenReport
		m.loading = true
		return m, tea.Batch(loadReport(m.eng), m.startTick())
	case "security":
		m.screen = screenSecurity
		m.security = nil
		m.loading = true
		return m, tea.Batch(loadSecurity(m.eng), m.startTick())
	case "apps":
		m.screen = screenApps
		m.pk = nil
		m.loading = true
		return m, tea.Batch(loadCatalog(m.eng, "apps"), m.startTick())
	case "cli":
		m.screen = screenCLI
		m.pk = nil
		m.loading = true
		return m, tea.Batch(loadCatalog(m.eng, "cli"), m.startTick())
	case "logs":
		m.screen = screenLogs
		m.lv = nil
		m.loading = true
		return m, tea.Batch(loadLogs(m.eng), m.startTick())
	case "install":
		m.screen = screenInstall
		inst, cmd := startDryRun(m.eng)
		m.inst = inst
		return m, tea.Batch(cmd, m.startTick())
	}
	return m, nil
}

// handlePickerKey drives an app/cli multi-select. Confirming hands the chosen
// keys to the shell installer; the TUI performs no installation itself.
func (m model) handlePickerKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	// Filter-typing mode captures printable keys until enter/esc.
	if m.pk.filtering {
		switch msg.Type {
		case tea.KeyEscape:
			m.pk.filtering = false
			m.pk.filter = ""
		case tea.KeyEnter:
			m.pk.filtering = false
		case tea.KeyBackspace:
			if r := []rune(m.pk.filter); len(r) > 0 {
				m.pk.filter = string(r[:len(r)-1])
			}
		case tea.KeyRunes, tea.KeySpace:
			m.pk.filter += string(msg.Runes)
		}
		m.pk.clampCursor()
		return m, nil
	}

	switch msg.String() {
	case "esc", "backspace", "left", "h", "q":
		if m.pk.filter != "" {
			// First esc clears the filter; the next one leaves the screen.
			m.pk.filter = ""
			m.pk.clampCursor()
			return m, nil
		}
		m.screen = screenDashboard
		m.pk = nil
		m.err = nil
	case "/":
		m.pk.filtering = true
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

// handleLogsKey drives the logs browser: the list picks a log, the pager
// scrolls it. esc backs out one level (pager → list → dashboard).
func (m model) handleLogsKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	back := func() (tea.Model, tea.Cmd) {
		if m.lv != nil && m.lv.open {
			m.lv.close()
			return m, nil
		}
		m.screen = screenDashboard
		m.lv = nil
		m.err = nil
		return m, nil
	}
	switch msg.String() {
	case "esc", "backspace", "left", "h", "q":
		return back()
	}
	if m.lv == nil { // still loading
		return m, nil
	}
	switch msg.String() {
	case "up", "k":
		m.lv.up()
	case "down", "j":
		m.lv.down()
	case "enter", "right", "l":
		if !m.lv.open {
			if e := m.lv.selected(); e != nil {
				content, err := m.eng.ReadLog(e.Path)
				if err != nil {
					m.err = err
					return m, nil
				}
				m.lv.setHeight(m.height)
				m.lv.openContent(e.Name, content)
			}
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
	case screenLogs:
		return m.frame("Logs", m.viewLogs())
	case screenInstall:
		return m.frame("Install", m.viewInstall())
	default:
		return m.frame("your macOS dev setup", m.viewDashboard())
	}
}

func (m model) viewPicker() string {
	if m.loading || m.pk == nil {
		return m.loadingView("loading catalog…", 4)
	}
	// Rows the frame can hold: chrome (border, padding, head, list header,
	// window markers, help) takes ~11 lines.
	rows := m.height - 11
	if rows < 5 {
		rows = 5
	}
	return m.pk.view(m.innerWidth(), rows)
}

func (m model) viewLogs() string {
	if m.loading || m.lv == nil {
		return m.loadingView("finding logs…", 2)
	}
	return m.lv.view()
}

func (m model) viewInstall() string {
	if m.inst == nil {
		return m.loadingView("starting…", 0)
	}
	return m.inst.view(m.innerWidth(), m.spin)
}

// loadingView is the shared skeleton: an animated spinner line plus muted
// placeholder rows where results will land.
func (m model) loadingView(text string, rows int) string {
	var b strings.Builder
	b.WriteString(styleCursor.Render(spinnerFrame(m.spin)) + " " + styleSubtle.Render(text) + "\n")
	for i := 0; i < rows; i++ {
		b.WriteString(styleSubtle.Render("  …") + "\n")
	}
	return b.String()
}

// innerWidth is the content width inside the app frame.
func (m model) innerWidth() int {
	w := m.width - 8
	if w < 40 {
		w = 40
	}
	return w
}

// frame wraps body content in the full-window app chrome: a rounded border,
// the title bar, and a help footer pinned to the bottom.
func (m model) frame(title, body string) string {
	head := styleTitle.Render("macstrap") + styleSubtle.Render("  ·  "+title)
	help := m.helpLine()
	if m.err != nil {
		body = styleErr.Render("error: "+m.err.Error()) + "\n\n" + body
	}

	// Without a real size yet, render unframed (also keeps tests simple).
	if m.width < 40 || m.height < 12 {
		return lipgloss.JoinVertical(lipgloss.Left, head, "", body, "", help)
	}

	innerH := m.height - 4 // border + vertical padding
	gap := innerH - lipgloss.Height(head) - 1 - lipgloss.Height(body) - lipgloss.Height(help)
	if gap < 1 {
		gap = 1
	}
	content := lipgloss.JoinVertical(lipgloss.Left,
		head, "", body, strings.Repeat("\n", gap-1), help)
	return lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(colorMuted).
		Padding(1, 2).
		Width(m.width - 2).
		Render(content)
}

func (m model) helpLine() string {
	switch m.screen {
	case screenDashboard:
		return styleHelp.Render("↑/↓ move · enter select · q quit")
	case screenApps, screenCLI:
		if m.pk != nil && m.pk.filtering {
			return styleHelp.Render("type to filter · enter keep · esc clear")
		}
		return styleHelp.Render("↑/↓ move · space toggle · / search · enter install · d preview · esc back")
	case screenLogs:
		if m.lv != nil && m.lv.open {
			return styleHelp.Render("↑/↓ scroll · esc back to list")
		}
		return styleHelp.Render("↑/↓ move · enter view · esc back")
	case screenInstall:
		if m.inst != nil && m.inst.done && !m.inst.fail {
			return styleHelp.Render("enter run install · esc back")
		}
		return styleHelp.Render("esc back · ctrl+c quit")
	case screenDoctor, screenSecurity:
		return styleHelp.Render("r rerun · esc back · ctrl+c quit")
	default:
		return styleHelp.Render("esc back · ctrl+c quit")
	}
}

// --- dashboard ---

func (m model) viewDashboard() string {
	actions := m.viewActions()
	status := m.viewStatus()
	rows := len(menu)
	if s := strings.Count(status, "\n") + 1; s > rows {
		rows = s
	}

	var panels string
	w := m.innerWidth()
	if w >= 76 {
		actionsW := 40
		statusW := w - actionsW - 2
		if statusW > 44 {
			statusW = 44
		}
		panels = lipgloss.JoinHorizontal(lipgloss.Top,
			titledPanel("Actions", actions, actionsW, rows),
			"  ",
			titledPanel("Status", status, statusW, rows),
		)
	} else {
		panels = titledPanel("Actions", actions, w, 0) + "\n" +
			titledPanel("Status", status, w, 0)
	}

	return panels + "\n\n" + m.nextAction()
}

func (m model) viewActions() string {
	var b strings.Builder
	for i, it := range menu {
		cursor := "  "
		// Pad before styling: ANSI codes would defeat %-Ns width math.
		title := styleBody.Render(fmt.Sprintf("%-9s", it.title))
		if i == m.cursor {
			cursor = styleCursor.Render("▸ ")
			title = styleCursor.Render(fmt.Sprintf("%-9s", it.title))
		}
		fmt.Fprintf(&b, "%s%s %s\n", cursor, title, styleSubtle.Render(truncate(it.desc, 24)))
	}
	return b.String()
}

// viewStatus is the at-a-glance machine state: report counts plus the
// background doctor summary.
func (m model) viewStatus() string {
	var b strings.Builder
	row := func(glyphStr, label, detail string, style lipgloss.Style) {
		fmt.Fprintf(&b, "%s %s %s\n", style.Render(glyphStr), styleBody.Render(fmt.Sprintf("%-13s", label)), styleSubtle.Render(detail))
	}

	if m.report == nil {
		row(spinnerFrame(m.spin), "Machine", "reading state…", styleCursor)
	} else {
		r := m.report
		row("✓", "Core tools", fmt.Sprintf("%d installed", r.Homebrew.Core), styleOK)
		row("✓", "Dotfiles", fmt.Sprintf("%d managed", r.DotfilesCount), styleOK)
		if r.Homebrew.Apps > 0 {
			row("✓", "Apps", fmt.Sprintf("%d tracked", r.Homebrew.Apps), styleOK)
		} else {
			row("○", "Apps", "none tracked yet", styleSubtle)
		}
		installed, missing := 0, 0
		for _, c := range r.CLI {
			if c.Status == "installed" {
				installed++
			} else {
				missing++
			}
		}
		switch {
		case missing > 0:
			row("!", "Project CLIs", fmt.Sprintf("%d installed · %d pending", installed, missing), styleWarn)
		case installed > 0:
			row("✓", "Project CLIs", fmt.Sprintf("%d installed", installed), styleOK)
		default:
			row("○", "Project CLIs", "none selected yet", styleSubtle)
		}
		fmt.Fprintf(&b, "\n%s %s\n", styleSubtle.Render("profile"), styleBody.Render(r.Profile))
	}

	b.WriteString("\n")
	switch {
	case m.doctor == nil:
		row(spinnerFrame(m.spin), "Health", "doctor running…", styleCursor)
	case m.doctor.Summary.Warn+m.doctor.Summary.Error > 0:
		row("!", "Health", fmt.Sprintf("%d of %d checks need attention",
			m.doctor.Summary.Warn+m.doctor.Summary.Error, len(m.doctor.Checks)), styleWarn)
	default:
		row("✓", "Health", fmt.Sprintf("all %d checks ok", len(m.doctor.Checks)), styleOK)
	}
	return strings.TrimRight(b.String(), "\n")
}

// nextAction is one guided suggestion derived from the machine state.
func (m model) nextAction() string {
	prefix := styleCursor.Render("→ ")
	switch {
	case m.doctor == nil || m.report == nil:
		return prefix + styleSubtle.Render("sizing up this machine…")
	case m.doctor.Summary.Error > 0 || m.doctor.Summary.Warn > 0:
		return prefix + styleBody.Render(fmt.Sprintf("Open Doctor — %d check(s) need attention.",
			m.doctor.Summary.Warn+m.doctor.Summary.Error))
	case len(m.report.CLI) == 0:
		return prefix + styleBody.Render("Add project CLIs for your stack — they replay on your next Mac.")
	case m.report.Homebrew.Apps == 0:
		return prefix + styleBody.Render("Pick GUI apps to install from the Apps screen.")
	default:
		return prefix + styleBody.Render("All healthy. Preview any change with Install — it dry-runs first.")
	}
}

// --- detail screens ---

func (m model) viewDoctor() string {
	if m.loading || m.doctor == nil {
		return m.loadingView("running checks…", 5)
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
		line := fmt.Sprintf("  %s %s %s",
			levelStyle(c.Level).Render(glyph(c.Level)),
			styleBody.Render(fmt.Sprintf("%-18s", c.Label)),
			levelStyle(c.Level).Render(c.Status),
		)
		if c.Hint != "" {
			line += styleSubtle.Render("  — " + c.Hint)
		}
		b.WriteString(line + "\n")
	}
	if s := doctorSuggestion(d); s != "" {
		b.WriteString("\n" + styleGroup.Render("Suggested action") + "\n  " + styleBody.Render(s) + "\n")
	}
	return b.String()
}

// doctorSuggestion surfaces the first failing check's hint as the next step.
func doctorSuggestion(d *engine.Doctor) string {
	for _, c := range d.Checks {
		if c.Level != "ok" && c.Hint != "" {
			return c.Hint
		}
	}
	return ""
}

func (m model) viewReport() string {
	if m.loading || m.report == nil {
		return m.loadingView("reading state…", 4)
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
		return m.loadingView("checking posture…", 5)
	}
	s := m.security
	var b strings.Builder
	b.WriteString(levelStyle(s.Overall).Render(strings.ToUpper(s.Overall)) + "\n\n")
	var suggest string
	for _, c := range s.Checks {
		fmt.Fprintf(&b, "  %s %s %s\n",
			levelStyle(c.Level).Render(glyph(c.Level)),
			styleBody.Render(fmt.Sprintf("%-20s", c.Label)),
			levelStyle(c.Level).Render(c.Detail),
		)
		if suggest == "" && c.Level != "ok" {
			suggest = c.Label + ": " + c.Detail
		}
	}
	if suggest != "" {
		b.WriteString("\n" + styleGroup.Render("Suggested action") + "\n  " + styleBody.Render(suggest) + "\n")
	}
	return b.String()
}
