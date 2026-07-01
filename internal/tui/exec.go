package tui

import (
	"os/exec"
	"path/filepath"

	"github.com/XavierAgostino/macstrap/internal/engine"
)

// execCommand builds the *exec.Cmd that hands control to the bash entrypoint,
// for use with tea.ExecProcess (which wires up stdio and restores the TUI).
func execCommand(eng *engine.Engine, args ...string) *exec.Cmd {
	return exec.Command("bash", append([]string{filepath.Join(eng.Repo, "bin", "macstrap")}, args...)...)
}
