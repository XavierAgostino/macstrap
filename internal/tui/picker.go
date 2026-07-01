package tui

import (
	"fmt"
	"strings"

	"github.com/XavierAgostino/macstrap/internal/engine"
	"github.com/charmbracelet/lipgloss"
)

// picker is a multi-select over a catalog (apps or cli) with a filter and a
// preview pane. It renders the catalog the engine decoded and, on confirm,
// hands the chosen keys to the shell installer — it never installs anything
// itself.
type picker struct {
	kind     string // "apps" | "cli"
	items    []engine.CatalogItem
	selected map[string]bool
	cursor   int // index into visible()

	recommended map[string]bool   // catalog defaults (apps) / recorded picks (cli)
	installed   map[string]string // key -> status from the report (cli only)

	filter    string // active substring filter
	filtering bool   // true while the user is typing after "/"
}

// newPicker builds a picker, pre-checking the catalog's sensible defaults:
// apps pre-select their "default" set; cli pre-selects what's already recorded.
// The report (may be nil) supplies installed/missing badges for recorded CLIs.
func newPicker(kind string, c *engine.Catalog, r *engine.Report) *picker {
	sel := make(map[string]bool)
	rec := make(map[string]bool)
	pre := c.Defaults
	if kind == "cli" {
		pre = c.Selected
	}
	for _, k := range pre {
		sel[k] = true
		rec[k] = true
	}
	inst := make(map[string]string)
	if kind == "cli" && r != nil {
		for _, e := range r.CLI {
			inst[e.Key] = e.Status
		}
	}
	return &picker{kind: kind, items: c.Items, selected: sel, recommended: rec, installed: inst}
}

// visible returns the items matching the filter, in catalog order.
func (p *picker) visible() []engine.CatalogItem {
	if p.filter == "" {
		return p.items
	}
	q := strings.ToLower(p.filter)
	var out []engine.CatalogItem
	for _, it := range p.items {
		hay := strings.ToLower(it.Key + " " + it.Description + " " + strings.Join(it.Categories, " "))
		if strings.Contains(hay, q) {
			out = append(out, it)
		}
	}
	return out
}

func (p *picker) clampCursor() {
	if n := len(p.visible()); p.cursor >= n {
		p.cursor = n - 1
	}
	if p.cursor < 0 {
		p.cursor = 0
	}
}

func (p *picker) up() {
	if p.cursor > 0 {
		p.cursor--
	}
}

func (p *picker) down() {
	if p.cursor < len(p.visible())-1 {
		p.cursor++
	}
}

func (p *picker) toggle() {
	vis := p.visible()
	if len(vis) == 0 {
		return
	}
	k := vis[p.cursor].Key
	p.selected[k] = !p.selected[k]
}

// current is the item under the cursor, or nil when the filter matches nothing.
func (p *picker) current() *engine.CatalogItem {
	vis := p.visible()
	if len(vis) == 0 || p.cursor >= len(vis) {
		return nil
	}
	return &vis[p.cursor]
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

// badge summarizes an item's state at the end of its row.
func (p *picker) badge(it engine.CatalogItem) string {
	if st, ok := p.installed[it.Key]; ok {
		if st == "installed" {
			return badgeOK.Render("installed")
		}
		// The report's other status is "recorded" — picked but not on disk yet.
		return badgeWarn.Render("not installed")
	}
	if p.recommended[it.Key] {
		return badgeMut.Render("recommended")
	}
	return ""
}

// view renders the list and, when there is room, a preview pane for the item
// under the cursor. width <= 0 renders the list alone (used by narrow
// terminals and the unit tests); maxRows <= 0 disables windowing.
func (p *picker) view(width, maxRows int) string {
	previewW := 34
	if width < 76 {
		return p.viewList(width, maxRows)
	}
	listW := width - previewW - 2
	left := lipgloss.NewStyle().Width(listW).Render(p.viewList(listW, maxRows))
	right := titledPanel("Preview", p.viewPreview(previewW-4), previewW, p.previewHeight(maxRows))
	return lipgloss.JoinHorizontal(lipgloss.Top, left, "  ", right)
}

// previewHeight keeps the preview panel from jumping as the cursor moves.
func (p *picker) previewHeight(maxRows int) int {
	h := len(p.visible()) + 1
	if h < 9 {
		h = 9
	}
	if maxRows > 0 && h > maxRows {
		h = maxRows
	}
	return h
}

func (p *picker) viewList(listW, maxRows int) string {
	var b strings.Builder
	n := len(p.chosen())
	verb := "install"
	if p.kind == "cli" {
		verb = "add"
	}
	head := fmt.Sprintf("%d selected — enter to %s, d to preview", n, verb)
	if p.filtering {
		head = "filter: " + p.filter + "▌"
	} else if p.filter != "" {
		head = fmt.Sprintf("filter: %s — %d match(es) · %s", p.filter, len(p.visible()), head)
	}
	fmt.Fprintf(&b, "%s\n\n", styleSubtle.Render(truncate(head, listW)))

	vis := p.visible()
	if len(vis) == 0 {
		b.WriteString(styleSubtle.Render("  nothing matches — esc clears the filter\n"))
		return b.String()
	}

	// Window the list so tall catalogs never overflow the frame.
	start, end := 0, len(vis)
	if maxRows > 0 && len(vis) > maxRows {
		start = p.cursor - maxRows/2
		if start < 0 {
			start = 0
		}
		if start > len(vis)-maxRows {
			start = len(vis) - maxRows
		}
		end = start + maxRows
	}

	// Description column sized to fit: fixed row parts (23) + badge column (14).
	descW := listW - 23 - 14
	if descW < 12 {
		descW = 12
	}
	if descW > 34 {
		descW = 34
	}

	if start > 0 {
		fmt.Fprintf(&b, "%s\n", styleSubtle.Render(fmt.Sprintf("  ↑ %d more", start)))
	}
	for i := start; i < end; i++ {
		it := vis[i]
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
		desc := truncate(it.Description, descW)
		if pad := descW - lipgloss.Width(desc); pad > 0 {
			desc += strings.Repeat(" ", pad)
		}
		line := fmt.Sprintf("%s%s %s %s",
			cursor,
			rowStyle.Render(box),
			rowStyle.Render(fmt.Sprintf("%-16s", it.Key)),
			styleSubtle.Render(desc),
		)
		if bdg := p.badge(it); bdg != "" {
			line += " " + bdg
		}
		b.WriteString(line + "\n")
	}
	if end < len(vis) {
		fmt.Fprintf(&b, "%s\n", styleSubtle.Render(fmt.Sprintf("  ↓ %d more", len(vis)-end)))
	}
	return b.String()
}

// viewPreview details the item under the cursor: the exact formula the shell
// will install, its kind, groups, and state.
func (p *picker) viewPreview(w int) string {
	it := p.current()
	if it == nil {
		return styleSubtle.Render("no match")
	}
	var b strings.Builder
	kw := func(k, v string) {
		fmt.Fprintf(&b, "%s %s\n", styleSubtle.Render(fmt.Sprintf("%-8s", k)), styleBody.Render(v))
	}
	b.WriteString(styleCursor.Render(it.Key) + "\n\n")
	kw("formula", it.Formula)
	kw("kind", it.Kind)
	if len(it.Categories) > 0 {
		kw("groups", strings.Join(it.Categories, ", "))
	}
	b.WriteString("\n" + styleSubtle.Render(wordWrap(it.Description, w)) + "\n")

	var state []string
	if p.selected[it.Key] {
		state = append(state, badgeOK.Render("selected"))
	}
	if st, ok := p.installed[it.Key]; ok {
		if st == "installed" {
			state = append(state, badgeOK.Render("installed"))
		} else {
			state = append(state, badgeWarn.Render("not installed"))
		}
	} else if p.recommended[it.Key] {
		state = append(state, badgeMut.Render("recommended"))
	}
	if len(state) > 0 {
		b.WriteString("\n" + strings.Join(state, badgeMut.Render(" · ")))
	}
	return b.String()
}

// wordWrap is a simple greedy wrap for plain (unstyled) text.
func wordWrap(s string, w int) string {
	if w < 8 {
		return s
	}
	words := strings.Fields(s)
	var lines []string
	cur := ""
	for _, wd := range words {
		if cur == "" {
			cur = wd
		} else if len(cur)+1+len(wd) <= w {
			cur += " " + wd
		} else {
			lines = append(lines, cur)
			cur = wd
		}
	}
	if cur != "" {
		lines = append(lines, cur)
	}
	return strings.Join(lines, "\n")
}
