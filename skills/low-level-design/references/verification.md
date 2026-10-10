# Verification

Three loops, all mandatory. The lesson's whole claim is that it was executed.

## Loop 1 — the code

Build the deliverable folder, then run every file in it until green. Only then write prose.

Three things must run, and all three before any prose exists:

```bash
./run_all.sh                                    # every demo, then every test
cd phases && python3 -m unittest discover       # the phase tests
python3 -m unittest test_<subject>              # the final model's tests
```

**Each phase pair must run with the other phases deleted.** Test that literally — copy the module and its test file into an empty directory and run both there:

```bash
for m in phases/phase*.py; do
    case "$m" in */test_*) continue;; esac
    b=$(basename "$m" .py); iso=$(mktemp -d)
    cp "phases/$b.py" "phases/test_$b.py" "$iso/"
    (cd "$iso" && python3 "$b.py" >/dev/null && python3 -m unittest "test_$b" 2>&1 | tail -1)
    rm -rf "$iso"
done
```

A test importing its own module is correct. A phase importing *another phase* is not, and a reader who opens one pair alone will hit an ImportError rather than a lesson.

The phase files repeat code. That duplication is deliberate and it has a cost: a late fix to the final model can leave a phase file stating the old design. Re-run every phase after any change to the final module, not only the suite.

**When a test fails, decide which side is wrong before changing either.** A wrong expectation in your own test is the common case. Silently adjusting the implementation to match a bad expectation produces a lesson that teaches a bug.

Observed on a real build: three of the first failures were arithmetic errors in the test — a discount chain computed by hand, and a misuse of the end-of-pages sentinel where `None` meant "start from the beginning" rather than "no more pages". The implementation was right all three times.

**Count with a command.** Never estimate.

```bash
grep -cE '^class [A-Za-z_]+' catalog.py          # classes
grep -cE '^check\(|^raises\(' test_catalog.py    # assertions
```

A first draft claimed thirty-one classes. The real count was fifty. A number a reader can check is the point; a wrong one destroys the warrant.

## Loop 2 — the prose

The page is read by a person, and an unreadable page fails whatever the code does. Measure before publishing; do not trust how the writing felt while producing it.

```bash
python3 - <<'PYEOF'
import re, pathlib
s = pathlib.Path("page.html").read_text()
text = " ".join(re.sub(r"<[^>]+>", "", p) for p in re.findall(r"<p>(.*?)</p>", s, flags=re.S))
sents = [x for x in re.split(r"(?<=[.!?])\s+", re.sub(r"\s+", " ", text)) if len(x.split()) > 2]
lens = [len(x.split()) for x in sents]
over = [x for x in sents if len(x.split()) > 25]
print(f"{len(sents)} sentences, mean {sum(lens)/len(lens):.1f}w, {len(over)} over 25w")
for x in sorted(over, key=lambda s: -len(s.split()))[:8]:
    print(f"  [{len(x.split())}w] {x[:120]}")
PYEOF
```

Mean under 20 words, nothing over 25. Every sentence the script prints gets split before publishing.

Observed on a real build: the first draft measured 18.7 words mean, which looked fine, while 25% of sentences ran over 25 words and the worst reached 48. The mean hides the problem — a page of short sentences plus a long tail reads as dense in exactly the places carrying the reasoning. **Check the count over 25, not the average.**

Two failures the script cannot catch, so read for them directly. One concept called by two names — search the page for each class name and see whether the surrounding prose uses a synonym anywhere. And a technical term used before it is glossed; a walkthrough that assumes its vocabulary stops teaching at that word.

## Loop 3 — the rendering

Serve the page and drive a real browser. `file://` is blocked, so use a local server.

```bash
cd "$SCRATCH" && (python3 -m http.server 8731 >/dev/null 2>&1 &)
playwright-cli open "http://localhost:8731/preview-light.html"
playwright-cli resize 1280 900
```

Wrap the artifact body in a minimal skeleton for preview, and make a second copy with `data-theme="dark"` on the root to check the other theme.

### Detect clipping programmatically

Do not eyeball a dozen diagrams. Measure each SVG's content against its declared viewBox.

**`getBBox()` on child elements ignores ancestor `transform`.** Class boxes emitted inside a translated `<g>` go uncounted, and every diagram reports clean while several are visibly cut. Measure from the SVG **root**, whose `getBBox()` does account for child transforms.

```js
JSON.stringify([...document.querySelectorAll('figure svg, .notationbox svg')].map(s => {
  const vb = s.getAttribute('viewBox').split(' ').map(Number);
  const b = s.getBBox();                       // root: transforms included
  return {l: (s.getAttribute('aria-label')||'').slice(0,30), w: vb[2], h: vb[3],
          mx: Math.round(b.x+b.width), my: Math.round(b.y+b.height)};
}))
```

Anything where `mx > w` or `my > h` is clipped. On a real build this caught six diagrams: three with class boxes past the bottom edge, three with footnote text past the right. Long footnotes overflow constantly — split them across two lines rather than widening the viewBox, so all diagrams keep one scale.

### Check the page as a whole

```js
JSON.stringify({
  svgWidth: Math.round(document.querySelector('figure svg').getBoundingClientRect().width),
  bodyOverflow: document.documentElement.scrollWidth > window.innerWidth,
  proseWidth: Math.round(document.querySelector('.prose').getBoundingClientRect().width)
})
```

Diagrams should render at or above their viewBox width — below it means text is shrinking. Prose should land near 60–70 characters. `bodyOverflow` must be false, at desktop and at roughly 960px.

### Then look

Screenshot the diagrams that changed and read them. Measurement catches clipping; only looking catches an edge routed through a node, a label struck through by a line, or an arrowhead pointing at empty space.

## Cleanup

Kill the server, close the browser, and delete stray screenshots — `playwright-cli` writes into `.playwright-cli` relative to the working directory, so run it from a scratch directory or the files land in the repo.
