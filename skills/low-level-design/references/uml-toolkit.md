# UML diagrams

## Why authored SVG, not screenshots

A rendered PNG from a diagram tool cannot follow the viewer's theme, blurs on a retina display, bloats the page as a data URI, and is invisible to a screen reader. Inline SVG driven by the page's CSS tokens beats it on every axis, and one build script keeps a dozen diagrams geometrically consistent.

Mermaid is the other tempting option. It gives correct class-diagram notation cheaply, but you surrender layout control and its theming fights a two-theme page. Author the SVG.

## The toolkit

`scripts/umlgen.py`. Import it into a build script, lay out coordinates by hand, write `.svg` files, then splice them into the page.

```python
import sys; sys.path.insert(0, ".../ood-lesson/scripts")
from umlgen import *

p = []
b, w, h = box(30, 40, "Product",
              ["- id: str", "- name: str"],
              ["+ add_variant(v): Variant"],
              stereotype="aggregate root")
p.append(b)
p.append(link(30 + w, 74, 300, 74, "comp", m1="1", m2="1..*", label="variants"))

svg = svg_open(940, 340, "Phase 1 class diagram") + "\n".join(p) + SVG_CLOSE
```

Every shape draws with `var(--token)` fills and strokes, so a single diagram renders in both themes. Keep every diagram on one viewBox width — 940 works well — so they all scale identically on the page.

| Helper | For |
|---|---|
| `box` | Three-compartment classifier with optional stereotype, abstract italics, accent stroke |
| `simple_class` | Name-only box, for the finished model where compartments will not fit |
| `link` | `assoc`, `gen`, `realize`, `dep`, `comp`, `agg`, with multiplicities and a mid-label |
| `note` | Folded-corner UML note |
| `actor`, `ellipse` | Use case diagrams |
| `state` | Initial, normal, final state nodes |
| `action`, `diamond`, `flow` | Activity diagrams |
| `package` | Tabbed folder for the finished model |
| `text` | Captions and footnotes |

## Which diagrams

| Diagram | Where | Shows what nothing else does |
|---|---|---|
| Notation key | Sheet A2 | How to read the rest |
| Use case | Sheet B | Actors, boundary, `«include»` |
| Class, one per phase | Each phase | Structure as it accumulates |
| Activity | The phase with a loop or branching algorithm | Decisions, guards, loops, what sits outside the loop |
| Sequence | The phase with cross-object collaboration | Ordering, activation, `alt` and `loop` fragments |
| State machine | The phase with a lifecycle | Legal transitions and terminal states |
| Finished class diagram | Sheet C | Packages and cross-boundary dependencies |

Do not draw a diagram type because the list has it. An activity diagram of a three-step method teaches nothing.

## Notation correctness

These are read as errors by anyone fluent in UML, and all are easy to get backwards.

**Composition, filled diamond, at the whole end.** The part dies with the whole — delete a product, its variants go.

**Aggregation, hollow diamond, at the whole end.** The part outlives the whole.

The diamond marks the *owner*. Drawing it at the part end inverts the meaning. In `umlgen`, the diamond renders at the `(x1, y1)` end, so order the coordinates owner-first.

**Generalization, hollow closed triangle, at the parent.** Solid line.

**Realization, hollow closed triangle, at the interface.** Dashed line. Use for anything implementing a `Protocol`.

**Dependency, open arrowhead, at the thing depended on.** Dashed. If Product uses Money, the arrow points at Money.

**Multiplicity at both ends**, on associations that have one.

**Interfaces** get an `«interface»` stereotype and an italic name.

## Layout

Route edges around nodes, never through them. Give a loop-back its own clear corridor — in an activity diagram, take it down and out to a margin rather than straight back across the body.

An edge that ends in empty space is a coordinate bug: check the target box's actual width before pointing at its centre.

Put opaque patches behind edge labels and guards so lines do not strike through text.

Footnote text inside a diagram overflows the viewBox constantly. Split it across two lines rather than widening one diagram out of step with the rest.

## Page layout

Give diagrams the full container width. A sidebar costs roughly 270px, which diagrams pay for directly in shrunken text — moving navigation to a horizontal strip took one build's diagrams from 0.94× to 1.17× of their native scale, about 24% larger text, changing nothing else.

Keep prose to its own 65–70 character measure while figures span the container. Each diagram sits in an `overflow-x: auto` wrapper with a sensible `min-width`, so narrow viewports scroll the figure instead of the page.
