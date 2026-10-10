# The reference model

The structure this skill produces is derived from the "Design a Parking Lot" lesson in Grokking the Object-Oriented Design Interview.

Source: https://www.designgurus.io/course-play/grokking-the-object-oriented-design-interview/doc/design-a-parking-lot

Use it two ways: as the shape to generate against, and as the thing to check a finished lesson against. It is a good model — it earns its reputation — but it is not a template to copy blindly, and the divergences below are deliberate.

## Its structure

Section headers, verbatim and in order:

1. Design a Parking Lot
2. System Requirements
3. Use case diagram
4. Building the design in five stages
5. Stage 1: the vehicles and the spots
6. Stage 2: a floor that can find a free spot
7. Stage 3: the ticket, the rate and the payment
8. Stage 4: the lot that ties it together
9. Stage 5: the panels the driver touches
10. The finished class diagram
11. The patterns in this design
12. What we left out, and what to say about it

**Requirements** are twelve numbered constraints, each a full sentence in the domain's own vocabulary, several carrying concrete figures rather than adjectives — "customers pay $4 for the first hour, $3.5 for the second and third hours, and $2.5 for every hour after that". A requirement with a number in it constrains the model. One without usually does not.

**Use case diagram** names four actors — Admin, Customer, Parking attendant, System — against eight use cases.

**Stages** each open by stating what the stage gives you, then a class diagram, then code, then annotations. The lesson's own instruction is to *"build in this order, and say what each stage gives you before you write it"*, and the stage outcomes are concrete: "After this stage the system can find and assign a spot. It can also report how many spots of each type are left."

**Diagrams**: a UML legend showing inheritance, composition, and association; a use case diagram; a cumulative class diagram after each stage; an activity diagram for the payment workflow, sitting between stages 3 and 4; and the finished composite diagram.

**Patterns** discusses Singleton and dismisses several other patterns as misnamed — that is, it declines patterns with reasons rather than listing every one it could have used.

**What we left out** names reservations, season tickets, number-plate recognition, and refunds as deliberate scope choices, then volunteers two criticisms of its own design: the five spot subclasses carry no behaviour and would be better as one class with a type field, and `ParkingLot` does two jobs at once. Omissions are framed as decisions, not oversights.

## What this skill takes from it

The sheet order, near enough. The instruction to state what each stage gives you before writing it. Requirements phrased concretely in the domain's vocabulary. A notation legend before any diagram that needs it. Cumulative class diagrams rather than one big reveal. Declining patterns with reasons. And self-criticism inside the omissions section — the skill's rule that a lesson must name its own worst coupling comes directly from this lesson doing exactly that.

## Where it deliberately diverges

**Five stages is that domain's answer, not a constant.** The reference has five because a parking lot decomposes into five. Carrying the number to another system produces padded or crowded phases. Derive the count from the four gates in `structure.md`.

**Its stage one is retrospective.** It opens with two inheritance hierarchies — vehicle types and spot types — which is only defensible because the author already knows stages 3 to 5 exist. A lesson that presents this as "start here" teaches a reader to build taxonomies before the second data point exists. State plainly when a phase's structure is justified by a later phase.

**Several of its classes carry no behaviour.** Admin, DisplayBoard, EntrancePanel, CustomerInfoPortal and the rest exist to satisfy the use case diagram, and the lesson concedes as much about the spot subclasses. This skill requires every class in the model to be exercised by the running code. A class nothing calls is a box on a diagram, not a design.

**Its code is illustrative; this skill's must execute.** The reference shows Python, Java, and C++ side by side, which trades depth for breadth and makes verification impractical. Pick one language, run it, and report counted numbers. See `verification.md`.

**Its pacing advice is interview pacing.** Guidance about running out of time and what to say to an interviewer does not belong in a design walkthrough. The instruction to state each stage's outcome survives that cut, because it is good pedagogy independently. The clock advice does not.

**It prefers subclasses where a field would do.** Five spot subclasses differing only in size is the exact case `structure.md` argues against by counterfactual — and the reference itself admits the fault in its closing section. Follow the admission, not the diagram.

## Validation checklist

Run a finished lesson against this. Anything unchecked is either a gap or a divergence you should be able to defend out loud.

- [ ] Requirements are concrete sentences in the domain's vocabulary, several carrying real figures
- [ ] Out-of-scope list is explicit
- [ ] Actors named, with a use case diagram
- [ ] A notation legend appears before the first diagram that needs it
- [ ] Every phase states what it gives you before any code
- [ ] Each phase has a class diagram showing the model as it stands, not only the delta
- [ ] At least one activity or sequence diagram covers a workflow that spans objects
- [ ] A finished class diagram recaps the whole model
- [ ] Patterns section names patterns declined, with reasons
- [ ] Omissions are framed as decisions, each with what the real version would need
- [ ] The lesson criticises its own design in at least two specific places
- [ ] Phase count is justified by the domain, not inherited
- [ ] Every class in the model is exercised by the running code
- [ ] Numbers in the lesson were counted with a command
- [ ] No phase introduces a hierarchy before its second variant exists, unless the lesson says why
- [ ] Every class traces back to a numbered requirement
- [ ] Every field and every method traces to a requirement or to a named rule it enforces
- [ ] The deliverable is a folder in the user's project, not a scratch directory
- [ ] Each phase is a module plus a sibling `unittest` test file, laid out like production code
- [ ] The module's `__main__` is a readable demo that asserts nothing
- [ ] Test methods are named after the rule they check, one per rule
- [ ] Every phase pair was run in an empty directory with the other phases removed
- [ ] Each listing on the page names its file and the command that runs it
- [ ] The final module and its test suite both run green
- [ ] Every requirement verb has a class to live on
- [ ] No subclass exists that only passes a constant to its parent
- [ ] Every inheritance arrow survives the substitution test
- [ ] Multiplicity appears on every association that has one
- [ ] The SOLID pass produced findings, and they are stated
- [ ] All seven principles have their own Sheet D entry, each naming the class, field, or relationship it changed
- [ ] The seven were run over the model before the implementation, not reported over finished code
- [ ] Every principle check was run against every class, not only the memorable ones
- [ ] At least one entry shows the model being changed because a check failed
- [ ] Every violation still in the design carries a written account of what fixing it would cost
- [ ] Where two principles pulled against each other, the walkthrough says which won and why
- [ ] Prose sentences average under 20 words, with none over 25 — measured, not estimated
- [ ] One term per concept throughout; no synonym variation for a class or domain noun
- [ ] Every unavoidable technical term is glossed at first use
- [ ] Every decision note names the cost of the choice, not only the rejected alternative
- [ ] Every decision note names the specific condition that would reverse it
- [ ] Forks are decided by counts, numbers, or test results rather than adjectives
