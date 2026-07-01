package tui

import (
	"fmt"
	"strings"
	"time"

	"github.com/XavierAgostino/macstrap/internal/engine"
)

// logsView browses the captured step logs from quiet-mode runs. It has two
// modes: a list of logs on entry, and a scrollable pager once one is opened.
// Read-only, like Doctor/Report — it never mutates anything.
type logsView struct {
	entries []engine.LogEntry
	cursor  int

	// Pager state, active while open.
	open   bool
	title  string
	lines  []string
	offset int
	height int // visible content rows, kept in sync with the window size
}

func newLogsView(entries []engine.LogEntry) *logsView {
	return &logsView{entries: entries, height: 18}
}

// setHeight sizes the pager window to the terminal, leaving room for the
// header, the log title, and the help footer.
func (l *logsView) setHeight(termHeight int) {
	h := termHeight - 8
	if h < 4 {
		h = 4
	}
	l.height = h
}

func (l *logsView) up() {
	if l.open {
		if l.offset > 0 {
			l.offset--
		}
		return
	}
	if l.cursor > 0 {
		l.cursor--
	}
}

func (l *logsView) down() {
	if l.open {
		if l.offset < l.maxOffset() {
			l.offset++
		}
		return
	}
	if l.cursor < len(l.entries)-1 {
		l.cursor++
	}
}

func (l *logsView) maxOffset() int {
	if m := len(l.lines) - l.height; m > 0 {
		return m
	}
	return 0
}

// selected returns the entry under the cursor, or nil when the list is empty.
func (l *logsView) selected() *engine.LogEntry {
	if l.cursor < 0 || l.cursor >= len(l.entries) {
		return nil
	}
	return &l.entries[l.cursor]
}

// openContent loads a log's text into the pager.
func (l *logsView) openContent(name, content string) {
	l.open = true
	l.title = name
	l.lines = strings.Split(strings.TrimRight(content, "\n"), "\n")
	l.offset = 0
}

func (l *logsView) close() {
	l.open = false
	l.lines = nil
	l.title = ""
}

func (l *logsView) view() string {
	if l.open {
		return l.viewPager()
	}
	return l.viewList()
}

func (l *logsView) viewList() string {
	if len(l.entries) == 0 {
		return styleSubtle.Render("no logs yet — they appear here after a quiet install writes step logs.")
	}
	var b strings.Builder
	fmt.Fprintf(&b, "%s\n\n", styleSubtle.Render(fmt.Sprintf("%d captured — enter to view", len(l.entries))))
	for i, e := range l.entries {
		cursor := "  "
		name := styleBody.Render(e.Name)
		if i == l.cursor {
			cursor = styleCursor.Render("▸ ")
			name = styleCursor.Render(e.Name)
		}
		meta := styleSubtle.Render(fmt.Sprintf("%s · %s", humanSize(e.Size), humanAge(e.ModTime)))
		fmt.Fprintf(&b, "%s%-28s %s\n", cursor, name, meta)
	}
	return b.String()
}

func (l *logsView) viewPager() string {
	var b strings.Builder
	total := len(l.lines)
	end := l.offset + l.height
	if end > total {
		end = total
	}
	fmt.Fprintf(&b, "%s   %s\n\n",
		styleGroup.Render(l.title),
		styleSubtle.Render(fmt.Sprintf("lines %d–%d of %d", l.offset+1, end, total)),
	)
	for _, ln := range l.lines[l.offset:end] {
		b.WriteString(styleBody.Render(ln) + "\n")
	}
	return b.String()
}

// humanSize renders a byte count compactly (e.g. "0 B", "1.2 KB").
func humanSize(n int64) string {
	switch {
	case n < 1024:
		return fmt.Sprintf("%d B", n)
	case n < 1024*1024:
		return fmt.Sprintf("%.1f KB", float64(n)/1024)
	default:
		return fmt.Sprintf("%.1f MB", float64(n)/(1024*1024))
	}
}

// humanAge renders how long ago a log was written, in coarse units.
func humanAge(t time.Time) string {
	d := time.Since(t)
	switch {
	case d < time.Minute:
		return "just now"
	case d < time.Hour:
		return fmt.Sprintf("%dm ago", int(d.Minutes()))
	case d < 24*time.Hour:
		return fmt.Sprintf("%dh ago", int(d.Hours()))
	default:
		return fmt.Sprintf("%dd ago", int(d.Hours()/24))
	}
}
