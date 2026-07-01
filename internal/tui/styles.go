// Package tui is macstrap's terminal UI. Every screen renders values decoded by
// internal/engine; no screen performs setup work itself.
package tui

import "github.com/charmbracelet/lipgloss"

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
