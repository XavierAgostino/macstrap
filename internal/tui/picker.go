package tui

import (
	"fmt"
	"strings"

	"github.com/XavierAgostino/macstrap/internal/engine"
)

// picker is a multi-select over a catalog (apps or cli). It renders the catalog
// the engine decoded and, on confirm, hands the chosen keys to the shell
// installer — it never installs anything itself.
type picker struct {
	kind     string // "apps" | "cli"
	items    []engine.CatalogItem
	selected map[string]bool
	cursor   int
}

// newPicker builds a picker, pre-checking the catalog's sensible defaults:
// apps pre-select their "default" set; cli pre-selects what's already recorded.
func newPicker(kind string, c *engine.Catalog) *picker {
	sel := make(map[string]bool)
	pre := c.Defaults
	if kind == "cli" {
		pre = c.Selected
	}
	for _, k := range pre {
		sel[k] = true
	}
	return &picker{kind: kind, items: c.Items, selected: sel}
}

func (p *picker) up() {
	if p.cursor > 0 {
		p.cursor--
	}
}

func (p *picker) down() {
	if p.cursor < len(p.items)-1 {
		p.cursor++
	}
}

func (p *picker) toggle() {
	if len(p.items) == 0 {
		return
	}
	k := p.items[p.cursor].Key
	p.selected[k] = !p.selected[k]
}

// chosen returns the selected keys in catalog order.
func (p *picker) chosen() []string {
	var out []string
	for _, it := range p.items {
		if p.selected[it.Key] {
			out = append(out, it.Key)
		}
	}
	return out
}

// selection is the chosen keys joined for the shell (macstrap apps a,b,c).
func (p *picker) selection() string { return strings.Join(p.chosen(), ",") }

func (p *picker) view() string {
	var b strings.Builder
	n := len(p.chosen())
	verb := "install"
	if p.kind == "cli" {
		verb = "add"
	}
	fmt.Fprintf(&b, "%s\n\n", styleSubtle.Render(fmt.Sprintf("%d selected — enter to %s, d to preview", n, verb)))

	for i, it := range p.items {
		box := "[ ]"
		rowStyle := styleBody
		if p.selected[it.Key] {
			box = "[x]"
			rowStyle = styleSelected
		}
		cursor := "  "
		if i == p.cursor {
			cursor = styleCursor.Render("▸ ")
			rowStyle = styleCursor
		}
		fmt.Fprintf(&b, "%s%s %s %s\n",
			cursor,
			rowStyle.Render(box),
			rowStyle.Render(fmt.Sprintf("%-16s", it.Key)),
			styleSubtle.Render(it.Description),
		)
	}
	return b.String()
}
