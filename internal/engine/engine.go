package engine

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

// Engine locates the macstrap repo and runs its scripts. It is the only place
// the Go layer knows about paths and process execution.
type Engine struct {
	// Repo is the macstrap checkout that owns bin/ and scripts/.
	Repo string
}

// New resolves the macstrap repo dir the same way the scripts do:
// $MACSTRAP_DIR, then $DOTFILES_DIR, then ~/Developer/workspaces/macstrap.
func New() *Engine {
	repo := os.Getenv("MACSTRAP_DIR")
	if repo == "" {
		repo = os.Getenv("DOTFILES_DIR")
	}
	if repo == "" {
		home, _ := os.UserHomeDir()
		repo = filepath.Join(home, "Developer", "workspaces", "macstrap")
	}
	return &Engine{Repo: repo}
}

// script returns the absolute path to a script under scripts/.
func (e *Engine) script(name string) string {
	return filepath.Join(e.Repo, "scripts", name)
}

// env passes DOTFILES_DIR through so the scripts resolve their own paths from
// the same repo, regardless of where the binary was launched.
func (e *Engine) env() []string {
	return append(os.Environ(), "DOTFILES_DIR="+e.Repo)
}

// runJSON runs a script with args and decodes its stdout into v. stderr is
// surfaced in the error so a broken contract is legible.
func (e *Engine) runJSON(ctx context.Context, v any, script string, args ...string) error {
	cmd := exec.CommandContext(ctx, "bash", append([]string{e.script(script)}, args...)...)
	cmd.Env = e.env()
	out, err := cmd.Output()
	if err != nil {
		if ee, ok := err.(*exec.ExitError); ok && len(ee.Stderr) > 0 {
			return fmt.Errorf("%s: %w: %s", script, err, ee.Stderr)
		}
		return fmt.Errorf("%s: %w", script, err)
	}
	if err := json.Unmarshal(out, v); err != nil {
		return fmt.Errorf("%s: decoding %s: %w", script, "JSON", err)
	}
	return nil
}

// Doctor runs dev-doctor.sh --json.
func (e *Engine) Doctor(ctx context.Context) (*Doctor, error) {
	var d Doctor
	return &d, e.runJSON(ctx, &d, "dev-doctor.sh", "--json")
}

// AppsCatalog runs apps.sh --list --json.
func (e *Engine) AppsCatalog(ctx context.Context) (*Catalog, error) {
	var c Catalog
	return &c, e.runJSON(ctx, &c, "apps.sh", "--list", "--json")
}

// CLICatalog runs cli.sh --list --json.
func (e *Engine) CLICatalog(ctx context.Context) (*Catalog, error) {
	var c Catalog
	return &c, e.runJSON(ctx, &c, "cli.sh", "--list", "--json")
}

// Plan resolves a comma-separated selection against a catalog ("apps" or "cli")
// without installing anything (<catalog>.sh <selection> --json).
func (e *Engine) Plan(ctx context.Context, catalog, selection string) (*Plan, error) {
	var p Plan
	script := "apps.sh"
	if catalog == "cli" {
		script = "cli.sh"
	}
	return &p, e.runJSON(ctx, &p, script, selection, "--json")
}

// Report runs report.sh --json.
func (e *Engine) Report(ctx context.Context) (*Report, error) {
	var r Report
	return &r, e.runJSON(ctx, &r, "report.sh", "--json")
}

// Security runs security-check.sh --json.
func (e *Engine) Security(ctx context.Context) (*Security, error) {
	var s Security
	return &s, e.runJSON(ctx, &s, "security-check.sh", "--json")
}

// Passthrough runs the bash entrypoint (bin/macstrap) with the given args,
// inheriting stdio, and returns its exit code. This is how scriptable
// subcommands keep working unchanged through the Go front end, and how the TUI
// hands control to the real installer.
func (e *Engine) Passthrough(args ...string) int {
	cmd := exec.Command("bash", append([]string{filepath.Join(e.Repo, "bin", "macstrap")}, args...)...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	cmd.Env = os.Environ()
	if err := cmd.Run(); err != nil {
		if ee, ok := err.(*exec.ExitError); ok {
			return ee.ExitCode()
		}
		return 1
	}
	return 0
}
