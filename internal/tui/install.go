package tui

import (
	"bufio"
	"os/exec"
	"regexp"
	"strings"

	"github.com/XavierAgostino/macstrap/internal/engine"
	tea "github.com/charmbracelet/bubbletea"
)

// installView streams `macstrap install --dry-run` inside the TUI so the plan
// appears line by line, then offers to hand off to the real installer.
//
// Only the NON-INTERACTIVE dry run is streamed: the real install can prompt
// (profile chooser, sudo for casks), and scripts/lib/ui.sh is explicit that
// captured prompts hang. So confirming hands the terminal to the shell via
// tea.ExecProcess, where the engine's own phase progress and spinners run.
type installView struct {
	lines []string // plan output so far (ANSI stripped, restyled)
	done  bool     // dry run finished
	fail  bool     // dry run exited non-zero
	ch    chan installEvent
}

type installEvent struct {
	line string
	done bool
	fail bool
}

type installLineMsg struct{ ev installEvent }

var ansiRe = regexp.MustCompile(`\x1b\[[0-9;]*m`)

// startDryRun launches the plan subprocess and returns the view plus the
// command that waits for its first event.
func startDryRun(eng *engine.Engine) (*installView, tea.Cmd) {
	v := &installView{ch: make(chan installEvent, 64)}
	cmd := execCommand(eng, "install", "--dry-run")
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		v.lines = []string{err.Error()}
		v.done, v.fail = true, true
		return v, nil
	}
	cmd.Stderr = cmd.Stdout
	if err := cmd.Start(); err != nil {
		v.lines = []string{err.Error()}
		v.done, v.fail = true, true
		return v, nil
	}
	go func(c *exec.Cmd, out *bufio.Scanner, ch chan installEvent) {
		for out.Scan() {
			ch <- installEvent{line: ansiRe.ReplaceAllString(out.Text(), "")}
		}
		ch <- installEvent{done: true, fail: c.Wait() != nil}
		close(ch)
	}(cmd, bufio.NewScanner(stdout), v.ch)
	return v, v.wait()
}

// wait is the Bubble Tea command that delivers the next subprocess event.
func (v *installView) wait() tea.Cmd {
	ch := v.ch
	return func() tea.Msg {
		ev, ok := <-ch
		if !ok {
			return nil
		}
		return installLineMsg{ev}
	}
}

// apply folds an event into the view and reports whether to keep waiting.
func (v *installView) apply(ev installEvent) bool {
	if ev.done {
		v.done = true
		v.fail = ev.fail
		return false
	}
	v.lines = append(v.lines, ev.line)
	return true
}

// view renders the streamed plan, restyled into the TUI's palette.
func (v *installView) view(width, tick int) string {
	var b strings.Builder
	if !v.done {
		b.WriteString(styleCursor.Render(spinnerFrame(tick)) + styleSubtle.Render(" computing plan…") + "\n\n")
	} else if v.fail {
		b.WriteString(styleErr.Render("✗ preview failed") + styleSubtle.Render(" — see output below") + "\n\n")
	} else {
		b.WriteString(styleOK.Render("✓ plan ready") + styleSubtle.Render(" — nothing has been changed") + "\n\n")
	}

	var body strings.Builder
	for _, ln := range v.lines {
		body.WriteString(styleInstallLine(ln) + "\n")
	}
	if len(v.lines) == 0 {
		body.WriteString(styleSubtle.Render("…"))
	}
	w := width
	if w <= 0 || w > 74 {
		w = 74
	}
	b.WriteString(titledPanel("Plan — dry run", body.String(), w, 0))

	if v.done && !v.fail {
		b.WriteString("\n\n" + styleBody.Render("enter") + styleSubtle.Render(" runs the full install in your terminal — the shell engine takes over with its own step progress, and the dashboard refreshes when it finishes."))
	}
	return b.String()
}

// styleInstallLine re-colors a stripped plan line with the TUI palette.
func styleInstallLine(ln string) string {
	trimmed := strings.TrimSpace(ln)
	switch {
	case strings.HasPrefix(trimmed, "==>"):
		return styleGroup.Render(ln)
	case strings.Contains(ln, ":"):
		// "  Key:   value" rows — mute the key, keep the value bright.
		i := strings.Index(ln, ":")
		return styleSubtle.Render(ln[:i+1]) + styleBody.Render(ln[i+1:])
	default:
		return styleBody.Render(ln)
	}
}
