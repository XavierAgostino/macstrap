// Package tui is macstrap's terminal UI. Every screen renders values decoded by
// internal/engine; no screen performs setup work itself.
package tui

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/x/ansi"
)

// Palette — a Vesper-flavored scheme (warm peach accent on near-black), matching
// the shell UI so the two layers feel like one product.
var (
	colorAccent = lipgloss.Color("#FFC799") // Vesper peach — primary accent
	colorFg     = lipgloss.Color("#E0E0E0")
	colorMuted  = lipgloss.Color("#6C6C6C")
	colorOK     = lipgloss.Color("#A6E3A1")
	colorWarn   = lipgloss.Color("#F9E2AF")
	colorErr    = lipgloss.Color("#F38BA8")
)

// Shared styles. Screens compose these rather than redefining colors.
var (
	styleTitle = lipgloss.NewStyle().Foreground(colorAccent).Bold(true)

	styleSubtle = lipgloss.NewStyle().Foreground(colorMuted)

	styleBody = lipgloss.NewStyle().Foreground(colorFg)

	styleOK    = lipgloss.NewStyle().Foreground(colorOK)
	styleWarn  = lipgloss.NewStyle().Foreground(colorWarn)
	styleErr   = lipgloss.NewStyle().Foreground(colorErr)
	styleGroup = lipgloss.NewStyle().Foreground(colorAccent).Bold(true)

	// Selected/cursor row in a list.
	styleCursor   = lipgloss.NewStyle().Foreground(colorAccent).Bold(true)
	styleSelected = lipgloss.NewStyle().Foreground(colorOK)

	// The status/help bar at the bottom of a screen.
	styleHelp = lipgloss.NewStyle().Foreground(colorMuted)

	// A panel border used to frame a screen's main content.
	stylePanel = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(colorMuted).
			Padding(0, 1)
)

// Row badges — short muted state words at the end of a list row
// (installed / recommended / selected · missing …). Kept lowercase and
// text-only to match the shell engine's status language.
var (
	badgeOK   = lipgloss.NewStyle().Foreground(colorOK)
	badgeWarn = lipgloss.NewStyle().Foreground(colorWarn)
	badgeMut  = lipgloss.NewStyle().Foreground(colorMuted)
)

// spinnerFrames animate loading states (braille dots, ~120ms per frame).
var spinnerFrames = []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}

// spinnerFrame picks the frame for a tick counter.
func spinnerFrame(tick int) string {
	return spinnerFrames[tick%len(spinnerFrames)]
}

// titledPanel draws a rounded box of exactly width cells with the title set
// into the top border — the detail that makes a region read as a pane instead
// of indented text. Content is clipped/padded to the inner width; if height > 0
// the body is padded to that many rows so side-by-side panels bottom-align.
func titledPanel(title, body string, width, height int) string {
	if width < 8 {
		width = 8
	}
	inner := width - 4 // "│ " + " │"
	lines := strings.Split(strings.TrimRight(body, "\n"), "\n")
	if height > 0 {
		for len(lines) < height {
			lines = append(lines, "")
		}
	}

	var b strings.Builder
	// Top border with inline title: ╭─ Title ────╮
	t := " " + title + " "
	dashes := width - 3 - lipgloss.Width(t)
	if dashes < 0 {
		dashes = 0
	}
	b.WriteString(styleSubtle.Render("╭─") + styleGroup.Render(t) +
		styleSubtle.Render(strings.Repeat("─", dashes)+"╮") + "\n")
	for _, ln := range lines {
		w := lipgloss.Width(ln)
		if w > inner {
			ln = truncate(ln, inner)
			w = lipgloss.Width(ln)
		}
		pad := inner - w
		if pad < 0 {
			pad = 0
		}
		b.WriteString(styleSubtle.Render("│") + " " + ln + strings.Repeat(" ", pad) + " " + styleSubtle.Render("│") + "\n")
	}
	b.WriteString(styleSubtle.Render("╰" + strings.Repeat("─", width-2) + "╯"))
	return b.String()
}

// truncate clips a styled line to max visible cells, appending an ellipsis.
// ansi.Truncate is escape-aware, so it never cuts inside a color sequence.
func truncate(s string, max int) string {
	if lipgloss.Width(s) <= max {
		return s
	}
	return ansi.Truncate(s, max-1, "…")
}

// levelStyle maps a contract level word (ok/warn/error) to its style.
func levelStyle(level string) lipgloss.Style {
	switch level {
	case "ok":
		return styleOK
	case "error":
		return styleErr
	default:
		return styleWarn
	}
}

// glyph is the status marker for a level: matches the shell engine's language.
func glyph(level string) string {
	switch level {
	case "ok":
		return "✓"
	case "error":
		return "✗"
	default:
		return "!"
	}
}
