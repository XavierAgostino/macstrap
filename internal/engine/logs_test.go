package engine

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestLogDirRespectsUILogDir(t *testing.T) {
	t.Setenv("UI_LOG_DIR", "/tmp/custom-logs")
	e := &Engine{Repo: "/nowhere"}
	if got := e.LogDir(); got != "/tmp/custom-logs" {
		t.Errorf("LogDir = %q, want /tmp/custom-logs", got)
	}
}

func TestLogDirFallsBackToTmpdir(t *testing.T) {
	t.Setenv("UI_LOG_DIR", "")
	t.Setenv("TMPDIR", "/var/tmpx")
	e := &Engine{Repo: "/nowhere"}
	if got, want := e.LogDir(), filepath.Join("/var/tmpx", "macstrap-logs"); got != want {
		t.Errorf("LogDir = %q, want %q", got, want)
	}
}

func TestLogsMissingDirIsEmpty(t *testing.T) {
	t.Setenv("UI_LOG_DIR", filepath.Join(t.TempDir(), "does-not-exist"))
	e := &Engine{Repo: "/nowhere"}
	entries, err := e.Logs()
	if err != nil {
		t.Fatalf("Logs: %v", err)
	}
	if len(entries) != 0 {
		t.Errorf("expected no entries, got %d", len(entries))
	}
}

func TestLogsListsAndReadsNewestFirst(t *testing.T) {
	dir := t.TempDir()
	t.Setenv("UI_LOG_DIR", dir)
	e := &Engine{Repo: "/nowhere"}

	// Two logs and a non-log file; the .log files should come back newest-first.
	write := func(name, body string) string {
		p := filepath.Join(dir, name)
		if err := os.WriteFile(p, []byte(body), 0o644); err != nil {
			t.Fatal(err)
		}
		return p
	}
	write("install-homebrew.log", "older\n")
	newest := write("clone-dotfiles.log", "Cloning…\nDone.\n")
	write("notes.txt", "ignore me")
	// Make clone-dotfiles the most recently modified.
	now := time.Now()
	if err := os.Chtimes(newest, now, now); err != nil {
		t.Fatal(err)
	}
	older := filepath.Join(dir, "install-homebrew.log")
	if err := os.Chtimes(older, now.Add(-time.Hour), now.Add(-time.Hour)); err != nil {
		t.Fatal(err)
	}

	entries, err := e.Logs()
	if err != nil {
		t.Fatalf("Logs: %v", err)
	}
	if len(entries) != 2 {
		t.Fatalf("expected 2 log entries, got %d", len(entries))
	}
	if entries[0].Name != "clone-dotfiles" {
		t.Errorf("newest entry = %q, want clone-dotfiles", entries[0].Name)
	}
	content, err := e.ReadLog(entries[0].Path)
	if err != nil {
		t.Fatalf("ReadLog: %v", err)
	}
	if content != "Cloning…\nDone.\n" {
		t.Errorf("ReadLog = %q, unexpected content", content)
	}
}
