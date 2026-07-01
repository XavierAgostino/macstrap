package engine

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"
)

// repoRoot walks up from the test file to the module root (where scripts/ lives).
func repoRoot(t *testing.T) string {
	t.Helper()
	dir, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	for {
		if _, err := os.Stat(filepath.Join(dir, "scripts", "dev-doctor.sh")); err == nil {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			t.Skip("could not locate repo root (scripts/); skipping")
		}
		dir = parent
	}
}

func newEngine(t *testing.T) *Engine {
	if _, err := exec.LookPath("bash"); err != nil {
		t.Skip("bash not available; skipping engine integration test")
	}
	return &Engine{Repo: repoRoot(t)}
}

func ctx(t *testing.T) context.Context {
	c, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	t.Cleanup(cancel)
	return c
}

func TestDoctorDecodes(t *testing.T) {
	e := newEngine(t)
	d, err := e.Doctor(ctx(t))
	if err != nil {
		t.Fatalf("Doctor: %v", err)
	}
	if d.Schema != "macstrap.doctor/v1" {
		t.Errorf("schema = %q, want macstrap.doctor/v1", d.Schema)
	}
	if len(d.Checks) == 0 {
		t.Error("expected at least one check")
	}
	if got := d.Summary.OK + d.Summary.Warn + d.Summary.Error; got != len(d.Checks) {
		t.Errorf("summary totals %d, but %d checks", got, len(d.Checks))
	}
}

func TestCatalogsDecode(t *testing.T) {
	e := newEngine(t)
	for _, tc := range []struct {
		name string
		load func(context.Context) (*Catalog, error)
	}{
		{"apps", e.AppsCatalog},
		{"cli", e.CLICatalog},
	} {
		t.Run(tc.name, func(t *testing.T) {
			c, err := tc.load(ctx(t))
			if err != nil {
				t.Fatalf("%s catalog: %v", tc.name, err)
			}
			if c.Schema != "macstrap.catalog/v1" {
				t.Errorf("schema = %q, want macstrap.catalog/v1", c.Schema)
			}
			if c.Catalog != tc.name {
				t.Errorf("catalog = %q, want %q", c.Catalog, tc.name)
			}
			if len(c.Items) == 0 {
				t.Errorf("%s catalog has no items", tc.name)
			}
		})
	}
}

func TestReportDecodes(t *testing.T) {
	e := newEngine(t)
	r, err := e.Report(ctx(t))
	if err != nil {
		t.Fatalf("Report: %v", err)
	}
	if r.Schema != "macstrap.report/v1" {
		t.Errorf("schema = %q, want macstrap.report/v1", r.Schema)
	}
}

func TestSecurityDecodes(t *testing.T) {
	e := newEngine(t)
	s, err := e.Security(ctx(t))
	if err != nil {
		t.Fatalf("Security: %v", err)
	}
	if s.Schema != "macstrap.security/v1" {
		t.Errorf("schema = %q, want macstrap.security/v1", s.Schema)
	}
}
