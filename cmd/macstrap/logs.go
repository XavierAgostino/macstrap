package main

import (
	"fmt"
	"os"

	"github.com/XavierAgostino/macstrap/internal/engine"
)

// handleLogs implements the Go-native `logs` subcommand. Logs are filesystem
// artifacts the engine writes and reads directly, so — unlike every other
// subcommand — this is not delegated to bash. With no argument it lists the
// captured step logs (newest first); `logs <name>` prints one to stdout so it
// pipes into a pager. Returns a process exit code.
func handleLogs(eng *engine.Engine, rest []string) int {
	entries, err := eng.Logs()
	if err != nil {
		fmt.Fprintln(os.Stderr, "macstrap:", err)
		return 1
	}

	if len(rest) >= 1 {
		name := rest[0]
		for _, e := range entries {
			if e.Name == name {
				content, err := eng.ReadLog(e.Path)
				if err != nil {
					fmt.Fprintln(os.Stderr, "macstrap:", err)
					return 1
				}
				fmt.Print(content)
				return 0
			}
		}
		fmt.Fprintf(os.Stderr, "macstrap: no log named %q in %s\n", name, eng.LogDir())
		return 1
	}

	if len(entries) == 0 {
		fmt.Printf("No logs yet in %s\n", eng.LogDir())
		return 0
	}
	for _, e := range entries {
		fmt.Printf("%-28s  %10s  %s\n", e.Name, byteCount(e.Size), e.Path)
	}
	return 0
}

// byteCount renders a size compactly for the CLI listing.
func byteCount(n int64) string {
	switch {
	case n < 1024:
		return fmt.Sprintf("%d B", n)
	case n < 1024*1024:
		return fmt.Sprintf("%.1f KB", float64(n)/1024)
	default:
		return fmt.Sprintf("%.1f MB", float64(n)/(1024*1024))
	}
}
