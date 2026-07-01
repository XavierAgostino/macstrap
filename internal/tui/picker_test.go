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
	p := newPicker("apps", sampleCatalog("apps"))
	if !p.selected["cursor"] {
		t.Error("apps picker should pre-select the default 'cursor'")
	}
	if p.selected["ghostty"] {
		t.Error("non-default 'ghostty' should start unselected")
	}
}

func TestNewPickerPreselectsRecordedCLI(t *testing.T) {
	p := newPicker("cli", sampleCatalog("cli"))
	if !p.selected["ghostty"] {
		t.Error("cli picker should pre-select the recorded 'ghostty'")
	}
}

func TestToggleAndSelectionOrder(t *testing.T) {
	p := newPicker("apps", sampleCatalog("apps")) // cursor pre-selected
	p.down()                                      // -> ghostty
	p.toggle()                                    // select ghostty
	p.down()                                      // -> raycast
	p.toggle()                                    // select raycast
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
	p := newPicker("apps", sampleCatalog("apps"))
	out := p.view()
	if !strings.Contains(out, "cursor") || !strings.Contains(out, "ghostty") {
		t.Error("view should list catalog keys")
	}
	if !strings.Contains(out, "[x]") || !strings.Contains(out, "[ ]") {
		t.Error("view should render both checked and unchecked boxes")
	}
}
