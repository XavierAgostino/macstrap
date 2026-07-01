// Package engine is the Go side of macstrap's engine/UI seam. It does not
// reimplement any setup logic: it shells out to the same scripts the CLI uses
// and decodes their versioned JSON contracts (see docs/JSON-CONTRACTS.md) into
// the typed values below. The TUI renders these; it never touches Homebrew,
// chezmoi, or mise directly.
package engine

// Doctor is macstrap.doctor/v1 — the environment health report.
type Doctor struct {
	Schema  string        `json:"schema"`
	Overall string        `json:"overall"` // ok | warn | error
	Summary DoctorSummary `json:"summary"`
	Checks  []DoctorCheck `json:"checks"`
}

// DoctorSummary counts checks by level.
type DoctorSummary struct {
	OK    int `json:"ok"`
	Warn  int `json:"warn"`
	Error int `json:"error"`
}

// DoctorCheck is a single environment check.
type DoctorCheck struct {
	Key    string `json:"key"`
	Group  string `json:"group"`
	Label  string `json:"label"`
	Status string `json:"status"` // raw status word (ok, missing, locked, ...)
	Level  string `json:"level"`  // ok | warn | error
	Hint   string `json:"hint"`   // advisory next step, may be empty
}

// Catalog is macstrap.catalog/v1 — a whole catalog (apps or cli) plus category
// and selection state.
type Catalog struct {
	Schema     string        `json:"schema"`
	Catalog    string        `json:"catalog"` // "apps" | "cli"
	Categories []string      `json:"categories"`
	Defaults   []string      `json:"defaults,omitempty"`  // apps only
	Selected   []string      `json:"selected,omitempty"`  // cli only
	Items      []CatalogItem `json:"items"`
}

// CatalogItem is one installable entry (key|formula|kind|categories|description).
type CatalogItem struct {
	Key         string   `json:"key"`
	Formula     string   `json:"formula"`
	Kind        string   `json:"kind"` // brew | cask
	Categories  []string `json:"categories"`
	Description string   `json:"description"`
}

// Plan is macstrap.plan/v1 — a resolved selection (keys only, installs nothing).
type Plan struct {
	Schema  string   `json:"schema"`
	Catalog string   `json:"catalog"`
	Keys    []string `json:"keys"`
}

// Report is macstrap.report/v1 — what macstrap manages on this machine.
type Report struct {
	Schema   string `json:"schema"`
	Profile  string `json:"profile"`
	Homebrew struct {
		Core int `json:"core"`
		Apps int `json:"apps"`
	} `json:"homebrew"`
	DotfilesCount int         `json:"dotfiles_count"`
	CLI           []ReportCLI `json:"cli"`
}

// ReportCLI is one recorded optional CLI and whether it is installed.
type ReportCLI struct {
	Key    string `json:"key"`
	Status string `json:"status"` // installed | recorded
}

// Security is macstrap.security/v1 — the posture summary.
type Security struct {
	Schema  string          `json:"schema"`
	Overall string          `json:"overall"` // ok | warn
	Checks  []SecurityCheck `json:"checks"`
}

// SecurityCheck is a single posture check.
type SecurityCheck struct {
	Key    string `json:"key"`
	Label  string `json:"label"`
	Level  string `json:"level"` // ok | warn
	Detail string `json:"detail"`
}
