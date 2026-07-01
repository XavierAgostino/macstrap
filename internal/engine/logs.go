package engine

import (
	"errors"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

// LogEntry is one captured step log from a quiet-mode run.
type LogEntry struct {
	Name    string    // step slug, without the .log suffix
	Path    string    // absolute path to the log file
	Size    int64     // bytes on disk
	ModTime time.Time // last write, used to sort newest-first
}

// LogDir returns the directory where the shell engine writes per-step logs in
// quiet mode. It mirrors UI_LOG_DIR in scripts/lib/ui.sh:
//
//	${UI_LOG_DIR:-${TMPDIR:-/tmp}/macstrap-logs}
//
// Keep this in sync with that default so the TUI reads the same files the
// installer writes.
func (e *Engine) LogDir() string {
	if d := os.Getenv("UI_LOG_DIR"); d != "" {
		return d
	}
	tmp := os.Getenv("TMPDIR")
	if tmp == "" {
		tmp = "/tmp"
	}
	return filepath.Join(tmp, "macstrap-logs")
}

// Logs lists the captured step logs, most recent first. A missing log directory
// is not an error — it just means no quiet-mode run has written logs yet, so the
// result is an empty slice.
func (e *Engine) Logs() ([]LogEntry, error) {
	dir := e.LogDir()
	des, err := os.ReadDir(dir)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return nil, nil
		}
		return nil, err
	}
	var out []LogEntry
	for _, de := range des {
		if de.IsDir() || !strings.HasSuffix(de.Name(), ".log") {
			continue
		}
		info, err := de.Info()
		if err != nil {
			continue
		}
		out = append(out, LogEntry{
			Name:    strings.TrimSuffix(de.Name(), ".log"),
			Path:    filepath.Join(dir, de.Name()),
			Size:    info.Size(),
			ModTime: info.ModTime(),
		})
	}
	sort.Slice(out, func(i, j int) bool { return out[i].ModTime.After(out[j].ModTime) })
	return out, nil
}

// ReadLog returns the contents of a captured log file.
func (e *Engine) ReadLog(path string) (string, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	return string(b), nil
}
