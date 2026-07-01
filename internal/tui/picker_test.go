package tui

import (
	"strings"
	"testing"

	"github.com/XavierAgostino/macstrap/internal/engine"
)

func sampleCatalog(kind string) *engine.Catalog {
	c := &engine.Catalog{
		Schema:  "macstrap.catalog/v1",
		Catalog: kind,
		Items: []engine.CatalogItem{
			{Key: "cursor", Formula: "cursor", Kind: "cask", Description: "AI code editor"},
			{Key: "ghostty", Formula: "ghostty", Kind: "cask", Description: "GPU terminal"},
			{Key: "raycast", Formula: "raycast", Kind: "cask", Description: "Launcher"},
		},
	}
	if kind == "cli" {
		c.Selected = []string{"ghostty"}
	} else {
		c.Defaults = []string{"cursor"}
	}
	return c
}

func TestNewPickerPreselectsDefaults(t *testing.T) {
	p := newPicker("apps", sampleCatalog("apps"), nil)
	if !p.selected["cursor"] {
		t.Error("apps picker should pre-select the default 'cursor'")
	}
	if p.selected["ghostty"] {
		t.Error("non-default 'ghostty' should start unselected")
	}
}

func TestNewPickerPreselectsRecordedCLI(t *testing.T) {
	p := newPicker("cli", sampleCatalog("cli"), nil)
	if !p.selected["ghostty"] {
		t.Error("cli picker should pre-select the recorded 'ghostty'")
	}
}

func TestToggleAndSelectionOrder(t *testing.T) {
	p := newPicker("apps", sampleCatalog("apps"), nil) // cursor pre-selected
	p.down()                                           // -> ghostty
	p.toggle()                                         // select ghostty
	p.down()                                           // -> raycast
	p.toggle()                                         // select raycast
	// Selection must be in catalog order regardless of toggle order.
	if got, want := p.selection(), "cursor,ghostty,raycast"; got != want {
		t.Errorf("selection = %q, want %q", got, want)
	}
	p.toggle() // deselect raycast
	if got, want := p.selection(), "cursor,ghostty"; got != want {
		t.Errorf("after deselect selection = %q, want %q", got, want)
	}
}

func TestPickerViewRendersCheckboxes(t *testing.T) {
	p := newPicker("apps", sampleCatalog("apps"), nil)
	out := p.view(0, 0) // narrow: list only, no windowing
	if !strings.Contains(out, "cursor") || !strings.Contains(out, "ghostty") {
		t.Error("view should list catalog keys")
	}
	if !strings.Contains(out, "[x]") || !strings.Contains(out, "[ ]") {
		t.Error("view should render both checked and unchecked boxes")
	}
}

func TestPickerWideViewIncludesPreviewPane(t *testing.T) {
	p := newPicker("apps", sampleCatalog("apps"), nil)
	out := p.view(100, 0)
	if !strings.Contains(out, "Preview") {
		t.Error("wide view should render the preview pane")
	}
	if !strings.Contains(out, "formula") {
		t.Error("preview should show the formula the shell will install")
	}
}

func TestPickerFilterNarrowsVisibleAndToggle(t *testing.T) {
	p := newPicker("apps", sampleCatalog("apps"), nil)
	p.filter = "gpu" // matches ghostty's description only
	p.clampCursor()
	vis := p.visible()
	if len(vis) != 1 || vis[0].Key != "ghostty" {
		t.Fatalf("visible = %v, want just ghostty", vis)
	}
	p.toggle() // must act on the filtered row, not the raw index
	if !p.selected["ghostty"] {
		t.Error("toggle under a filter should select the visible item")
	}
	p.filter = ""
	if got, want := p.selection(), "cursor,ghostty"; got != want {
		t.Errorf("selection = %q, want %q", got, want)
	}
}

func TestPickerBadgesFromReport(t *testing.T) {
	r := &engine.Report{CLI: []engine.ReportCLI{
		{Key: "ghostty", Status: "installed"},
		{Key: "raycast", Status: "recorded"},
	}}
	p := newPicker("cli", sampleCatalog("cli"), r)
	if got := p.badge(p.items[1]); !strings.Contains(got, "installed") {
		t.Errorf("ghostty badge = %q, want installed", got)
	}
	if got := p.badge(p.items[2]); !strings.Contains(got, "not installed") {
		t.Errorf("raycast badge = %q, want not installed", got)
	}
}
