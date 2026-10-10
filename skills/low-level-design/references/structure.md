# Lesson structure

Sheets in order. Scale each to the domain; do not pad a sheet that has nothing to say.

## Title block

System, domain, language, phase count, class count, assertion count, diagram count. These are the reader's warrant that the lesson was executed rather than imagined, so every number must be countable.

## Sheet A — System requirements

Turn the one-line subject into a specification. Functional requirements as prose, each traceable to a later phase. Non-functional requirements that actually constrain the model — "money must reconcile to the minor unit" constrains; "should be scalable" does not. Then an explicit out-of-scope list.

Naming the boundary is part of the lesson. A model that pretends to cover search relevance, tax, and fulfilment teaches less than one that says plainly which subsystems it excludes and why each is its own problem.

## Sheet A2 — Reading the diagrams

A UML notation key: annotated three-compartment classifier, the six relationship types, visibility markers, multiplicity.

Spend a paragraph on aggregation versus composition specifically. Both mean "has a", the distinction is the one readers most often get wrong, and the answer is whether the part dies with the whole.

## Sheet B — Actors and use cases

A use case diagram, plus a table of actors, their use cases, and what each touches.

Then find the split between two actors that shapes the model, and state it in one explicit sentence. In a catalog it is the merchandiser editing shared content versus the store manager editing their own price and stock, which justifies the entire multi-tenant design before any code exists. Every domain has an equivalent — a parking lot has the attendant against the facility owner. Find it, because it lets a later phase be justified from the requirements rather than from a pattern, and that derivation is the part a reader can reuse.

## Phases 1 to N

**Choosing them.** The class list and relationships from `deriving-the-model.md` set the boundaries — a phase that cuts across a composition is usually cutting in the wrong place. A phase qualifies only if it satisfies all four gates:

1. It produces a working slice — something runnable and demonstrable alone.
2. It introduces exactly one significant idea.
3. It depends only on phases before it.
4. It is the question a reader would naturally ask next, having seen the previous one.

Order by dependency, not importance. At least one phase must be a genuine structural fork — where the obvious model breaks and a different one is required — and the lesson must say so explicitly, because that moment is what the reader came for. If a phase is only reachable by inventing a requirement nobody asked for, cut it.

**Each phase carries, in order:**

- Header with number, title, and one line on what this phase gives you.
- Prose that leads with the trap: what most people reach for here and why it does not hold. The reasoning is the transferable part.
- A UML class diagram for the phase.
- A relationships list in plain words, with cardinality and whether each is composition or reference. This doubles as the text alternative to the diagram.
- The file name and the command that runs this phase, stated before the listing: `phases/phase3_overrides.py`, `python3 phases/phase3_overrides.py`. A reader must be able to run the thing they are reading.
- One code listing lifted verbatim from that file. Twenty to thirty-five lines — the part carrying the idea, not the whole file. Comment only where the reasoning is invisible from the code.
- A justification line for anything new this phase introduces. Name the requirement number each class, field, and method serves, or the rule it enforces. A field serving nothing is scaffolding: delete it, or say what it is for.
- Real verified output where the phase produces any.
- At least one decision note, marked as such, first person, at the fork.

**A decision note carries four parts, in this order. A note missing any of them is a justification, not a judgement.**

1. **The choice**, in one sentence.
2. **The alternative that was rejected**, stated fairly enough that a reader can see why someone would pick it. If the rejected option sounds obviously stupid, it has been described unfairly, and the note teaches nothing.
3. **What the choice costs.** Every real decision buys one property with another. A note claiming a free win is a note that has not found the price yet — keep looking, because the reader will find it.
4. **The condition that would reverse it.** Name the specific change in requirements, scale, or team that flips the answer. "If read volume grows" is weak. "At roughly ten thousand listings per page load, resolution becomes a join per row, and I would materialise" is a judgement someone can act on.

A note that only restates what the code does is wasted. So is one that lists a trade-off without saying which side won and why.

**Engineering judgement is the part that transfers.** The code in a walkthrough is disposable — a reader's domain is different. What survives is the reasoning: how a fork was recognised, which forces were weighed, what evidence decided it. Show the weighing, including the parts that were close. A design where every decision was obvious is a design nobody had to think about, and reading it teaches nobody how to think.

Prefer evidence over assertion at every fork. "Three implementations already exist" beats "this is more extensible". "The tests stayed green after deleting it" beats "the class was unnecessary". A number, a count, or a passing test is judgement a reader can check; an adjective is not.

## Sheet C — The finished model

A full class diagram, packages as UML folder shapes, cross-package edges marked identifier-only.

Then state the partitioning principle. For business systems it is usually rate of change rather than subject similarity — pricing changes weekly, stock changes per order, catalog structure changes quarterly — and saying that is worth more than the diagram. A second figure showing the change-rate partition earns its place.

## Sheet D — Principles and patterns

Not a recitation. Each principle tied to the line where it changed a decision.

**Every one of the seven principles from step 4 of `deriving-the-model.md` gets its own entry, and every entry says where it bit.** Not that the principle is good, not that the design broadly honours it — the specific class, field, or relationship that came out different because the check was run. This is the sheet's spine, so give the seven their own section rather than scattering them through the prose.

| Principle | The entry must name |
|---|---|
| Start with the data | The field whose writer decided a boundary, and the boundary it decided |
| High cohesion | A class that passed the one-sentence test and one that failed it |
| Low coupling | The class naming the most types, and whether that is a boundary doing its job or a defect |
| Favour composition over inheritance | The counterfactual, with the actual multiplication |
| Depend on abstractions | The dependency that points at an interface, and any that still points at a concrete type |
| Separate creation from use | Where construction was pulled out of a class that uses the result — or why it was left in |
| Keep it simple | Something deleted, merged, or declined, with what was verified after removing it |

An entry that only restates the principle in the domain's vocabulary is not an entry. "The catalog keeps things simple" says nothing; "the two product subclasses were written, tested green, then deleted when it turned out one had a body of a single constant" is checkable, and the reader can go and look.

**Two of the seven will disagree somewhere in any real model** — cohesion pushes toward more classes, coupling toward fewer connections. Say which won and why. A sheet where all seven agree is a sheet where at least one was not run.

**Most entries should report a refactor, not a finding.** The principles are constraints applied during derivation, so the normal entry reads "cohesion failed on X, so X was split into Y and Z" — the model changed. An entry reporting an unfixed violation is the exception, and it must say what fixing it would require and why that cost was not worth paying here. An entry that merely notes a violation, with no fix and no justification, is a defect the walkthrough is displaying rather than a lesson it is teaching.

Three things make this sheet credible rather than performative. Name the design's own worst coupling before the reader finds it. List the patterns you deliberately declined and why — declining one with a reason teaches more than applying one. And show at least one place a check **forced the model to change**: the class that was split, merged, or deleted because a principle failed. A sheet where nothing changed is a sheet where nothing was checked.

The counterfactual is what makes composition-over-inheritance land: show that the inheritance version explodes combinatorially, with the actual multiplication.

The rest of the sheet, in roughly this order: the patterns table with what each one bought, and SOLID with the concrete bite for each.

## Sheet E — What we left out

A table of omissions, each with an honest one-line account of what the real version would need.

Then a separate paragraph naming the weaknesses in what you did build. A lesson with no self-identified flaws is not credible, and a reader who cannot see the seams learns to trust models further than they should be trusted.

## Sheet F — Exercises

Close by handing the work back. A lesson the reader only reads teaches far less than one they extend.

Give three or four concrete exercises drawn from the model itself: introduce a new requirement and predict which phase's structure breaks first; implement a phase that was only drawn; find the design's worst coupling before reading Sheet D's answer; re-partition the packages by a different principle and say what gets worse.

Each exercise should have a checkable outcome, so a reader working alone can tell whether they got it right.

## Writing constraints

Plain prose and code. No emoji, no status markers, no confidence percentages, no "Executive Summary" headers, no bulleted lists where every item opens with the same verb form. Concrete detail over generality.

Never state a fact you have not checked.

### Write in Simplified Technical English

Follow the principles of ASD-STE100. A reader works to follow the design; they must not also work to follow the sentence.

**One idea per sentence. Aim for 20 words. Never exceed 25.** This is the rule that does the most work, and it is the one most often broken while writing prose that feels fluent. Count the words in any sentence carrying a dash, a colon, and a comma-joined clause — it is usually over 30, and it is usually two or three sentences that were never separated.

**Active voice, present tense.** "The listing owns its offers", not "offers are owned by the listing". Name the actor performing every action.

**One term per concept, always the same term.** Pick `listing` or `store product`, then never use the other. Synonym variation is a habit from essay writing and it is a defect here: a reader cannot tell whether a new word means a new thing. This applies to the model's own vocabulary above all — if the class is `Offer`, the prose says offer, not "price record" or "the store's entry".

**Explain a term the first time it appears.** Multi-tenant, aggregate root, minor unit, cartesian product, denormalised — each gets a short gloss at first use. A walkthrough teaches; assumed vocabulary is where teaching quietly stops.

**Split, do not join.** When a sentence needs an em dash, a semicolon, or a parenthesis to hold a second thought, that thought is a sentence. Two plain sentences beat one elegant compound.

Prose sentences under 20 words on average, with none over 25, is the target. Measure it before publishing rather than trusting the feel of it:

```bash
python3 - <<'EOF'
import re, pathlib
s = pathlib.Path("page.html").read_text()
text = " ".join(re.sub(r"<[^>]+>", "", p) for p in re.findall(r"<p>(.*?)</p>", s, flags=re.S))
sents = [x for x in re.split(r"(?<=[.!?])\s+", re.sub(r"\s+", " ", text)) if len(x.split()) > 2]
lens = [len(x.split()) for x in sents]
print(f"mean {sum(lens)/len(lens):.1f}w, {sum(1 for l in lens if l>25)} over 25w")
for x in sorted(sents, key=lambda s: -len(s.split()))[:5]:
    print(f"  [{len(x.split())}w] {x[:110]}")
EOF
```

Anything over 25 words gets split before publishing. No exceptions for a sentence you like.
