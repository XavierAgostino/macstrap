// Command macstrap is the Go front end for the macstrap dev-setup bootstrapper.
//
// With no arguments it opens the TUI. With a subcommand it stays scriptable:
// every subcommand and flag is delegated, unchanged, to the bash entrypoint
// (bin/macstrap), so `macstrap doctor --json`, `macstrap install --dry-run`,
// etc. behave identically whether a human or a script invokes them.
//
// The Go layer never reimplements setup logic; it renders (TUI) or delegates
// (CLI). See docs/JSON-CONTRACTS.md for the engine/UI seam.
package main

import (
	"fmt"
	"os"

	"github.com/XavierAgostino/macstrap/internal/engine"
	"github.com/XavierAgostino/macstrap/internal/tui"
)

// version is set at build time by GoReleaser (-X main.version=...).
var version = "dev"

func main() {
	eng := engine.New()
	args := os.Args[1:]

	if len(args) == 1 {
		switch args[0] {
		case "--version", "-v", "version":
			fmt.Println("macstrap", version)
			return
		}
	}

	if len(args) == 0 {
		if err := tui.Run(eng); err != nil {
			fmt.Fprintln(os.Stderr, "macstrap:", err)
			os.Exit(1)
		}
		return
	}

	// Scriptable path: delegate verbatim to the shell engine and mirror its
	// exit code so CI and pipes see the real result.
	os.Exit(eng.Passthrough(args...))
}
