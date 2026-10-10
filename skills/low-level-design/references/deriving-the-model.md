# Deriving the model

`structure.md` says what the finished walkthrough contains. This says how to get there from a one-line subject — the procedure that turns "design a parking lot" into twelve classes with justified relationships.

The method is adapted from the method chapters of Grokking the Object-Oriented Design Interview, which precede its case studies. See `designgurus-model.md` for the source and for where this skill parts company with it.

## A note on ordering

The source runs five steps — requirements, actors, classes, relationships, then code last. That is the order for *deriving a design*, and it is right.

This file runs six, because it inserts a principles pass (step 4) between the relationships and SOLID. The source has no equivalent, and its absence is why its own case study ships five spot subclasses that differ only by a constant — a "keep it simple" check run before the code would have caught that, and the source only catches it in its closing self-criticism.

It is not the order for *authoring a walkthrough*, where the implementation must be green before any prose exists. There is no contradiction: derive the model in the order below, write it as running code, and only then write the lesson around it. Do not read "code last" as licence to publish unexecuted listings.

## Step 1 — Bound the subject

A requirement is one thing the system must do, written so you can tell whether the design does it. "Customers can pay at the exit" qualifies. "The parking lot should be good" does not.

Four questions, in order:

1. **Who uses this?** The actors — people and systems that touch the product. Each brings requirements the others do not.
2. **What can each of them do?** One actor at a time. Each action is a use case. Most of the list comes from here.
3. **What are the limits?** Numbers and rules. How many floors, how long a hold lasts, how many books a member may keep. Limits become constants and validation.
4. **What is out of scope?** The most valuable question and the one most often skipped. It is the only one of the four that makes the problem smaller.

Aim for eight to twelve in-scope lines. Every class you write later should trace back to one of them, and a class that traces to nothing is a class nobody asked for.

**Two habits make the list usable.**

*Write the number.* Not "a member can borrow a few books" but "a member can hold at most five books at a time". The number becomes a constant, and the constant becomes a check in one method.

*Name the actor.* Not "books can be reserved" but "a member can reserve a copy that is currently on loan". Now you know which class the method belongs on.

A requirement written this way is almost a test. You can point at a method and say this line is where requirement five lives.

## Step 2 — Find the classes

**Collect candidates.** Underline every noun in the requirements. The list will be too long, and that is fine — it is a candidate list, and its value is that nothing in it was invented. Underline the verbs too. Verbs become methods, and each one must end up on a class.

**Cut what is not a class.** Five tests:

1. **Is it a value rather than a thing?** An hour is a number. A licence plate is a string. Cash and card are two values of one payment type. Values become fields or enum constants.
2. **Is it the same thing under another name?** Customer and driver are one actor. Merge and pick one name.
3. **Does it have state that changes?** A spot is free or occupied, so it is a class. An hour never changes, so it is not.
4. **Does anything ask it a question?** A candidate becomes a class when other code needs to call it.
5. **Does this type differ in behaviour, or only in a value?**

The fifth test removes more candidates than the other four together, and it is where most designs go wrong.

Compact, large, and handicapped spots all appear in the requirements, and it is tempting to write three classes. Ask what is actually different. Each holds a vehicle, reports whether it is free, and has a number. The only difference is which vehicles fit — a value. One class with a type field covers all three.

Now compare a payment. Cash checks that enough money was handed over; card calls a provider and waits. Different behaviour, so different classes.

**Different data means a field. Different behaviour means a class.**

This is visible in a diagram without reading code: a tree of subclasses whose bodies only pass a different constant to the parent is a field written as several classes.

**Give each class one responsibility**, statable in one sentence that does not need the word "and". When the sentence needs an "and", that is the signal to split. With no clock running there is no excuse not to.

**Place the methods.** Each verb belongs on the class that owns the data it touches. "Find a free spot" touches the collection of spots, which the floor owns. When a method needs data from three classes to do its job, it is in the wrong place — move it to whichever class owns most of what it touches.

**Two invariants worth checking explicitly:**

- A verb with no class to live on means a class is missing.
- A class with no verbs is probably a value.

## Step 3 — Connect the classes

A relationship is a claim about **lifetime** and **substitution**, not about convenience. Getting it wrong is visible in the diagram without reading a line of code.

Ask four questions in order and **stop at the first yes**:

1. **Can B be used anywhere A is expected, with no surprises?** Inheritance. If any method of A would have to be refused, the answer is no.
2. **Does B die when A dies?** Composition.
3. **Is B a part of A, but able to exist on its own?** Aggregation.
4. Otherwise it is a plain association.

Most pairs are plain associations, and that is correct. A design where everything inherits from everything has not been thought about. Choose inheritance last.

**Multiplicity is half the claim.** Saying two classes are associated without saying how many leaves the reader guessing, and the number changes the code: `0..1` means the field can be null and every reader must check; `1..*` means a collection that must never be empty, which is a rule somebody has to enforce. Put a number on every line as you draw it.

**Two inheritance failures cover almost all of them.**

*The subclass that only carries a constant.* Three spot classes whose constructors pass different values to the parent and do nothing else. That is a field. A fourth type should be a new enum constant, not a new class.

*The subclass that must refuse something.* A requirement says a guest cannot place an order, so `Guest extends Customer` — and now a guest has an order the requirement forbids. This is question one failing. Move ordering off the shared parent onto the registered customer, so a guest never inherits what it must refuse.

Both have the same shape: inheritance used to share a little data, by classes that never passed the substitution test.

**When unsure, hold rather than extend.** A `FlyingBird` subclass breaks the moment a penguin arrives; a bird that holds a movement style does not. What an object holds can change at run time. What a class extends cannot.

Inheritance is right when the subclasses genuinely behave differently and every one honours the parent's promises. Cash and card payments both really do take money, differently.

## Step 4 — Design against the seven principles, and refactor until they hold

> **HARD RULE. The principles are design constraints, not a report card.**
>
> You do not build a model and then grade it. You build the model *while holding these seven and SOLID in mind*, and **the moment a check fails, you refactor the model there and then** — before moving on, before writing code, before drawing a diagram.
>
> **A design that violates a principle is not finished.** Go back and change it. Merge the class, split the class, invert the dependency, delete the field, move the method. Then re-run every check, because a fix in one place breaks another.
>
> Shipping a violation is the **exception**, and it costs you a written justification: what fixing it would require, and why that cost is not worth paying *here*. "I noticed it" is not a justification. A finding with no such reasoning is a defect in the design, not a teaching point.

SOLID in step 5 checks the class structure. These seven check the decisions that produced it, and they run first because several of them can still change the model cheaply at this point. Each has a test that yields a yes or a no, not an impression.

| Principle | The check that decides it | Fails when |
|---|---|---|
| Start with the data | For every field, name who writes it. Fields with different writers belong to different objects | One object holds fields written by two different actors |
| High cohesion | State each class's responsibility in one sentence with no "and" | The sentence needs an "and", or the class name is a category rather than a thing |
| Low coupling | Count the types each class names. Compare the highest against where your boundaries are | The highest count sits on a leaf class rather than at a deliberate boundary |
| Favour composition over inheritance | Multiply the independent axes of variation. Compare that number against the composed version's additions | The inheritance version multiplies where the composed version adds |
| Depend on abstractions | Follow each dependency arrow from high-level to low-level. It should end at an interface | A high-level class names a concrete low-level type, or builds its own collaborator |
| Separate creation from use | Find every place an object is constructed. Ask whether the constructing class also uses it | A class picks which concrete type to build *and* then drives it |
| Keep it simple | For each class, ask what breaks if it is deleted and its work inlined | Nothing breaks — the class was carrying no behaviour |

**The first one runs before the others, and it does the most work.** Naming the writer of every field is what produces the object boundaries; the remaining six mostly confirm or correct boundaries that step already drew. In a multi-tenant catalog, asking who writes `price` versus who writes `title` is what splits the shared definition from the per-store listing, and no amount of noun-underlining gets there as directly.

**Two of the seven routinely disagree, and that is the point.** Low coupling pushes toward fewer connections; high cohesion pushes toward classes small enough to state in one sentence, which makes more of them. When they pull against each other, say which one you let win and why — that sentence is worth more to a reader than either principle stated on its own.

**Do not soften a finding into a mention.** "Keep it simple" is satisfied by deleting something, not by observing that the design is fairly simple. A principle whose entry has no consequence — no class merged, split, deleted, or deliberately left as it is with a stated reason — was not actually run. Record the outcome of each as you go; step 6 hands the record to Sheet D, which must state where each of the seven bit.

### The loop — run it until the model stops changing

The seven are not a single pass. Fixing one violation routinely creates another, so this is a loop with a termination condition:

1. Run all seven checks over the current model.
2. **Any failure? Refactor the model to remove it.** Not a note. A change.
3. Re-run all seven from the top, because the refactor may have broken a check that passed a minute ago.
4. Stop when a full pass produces no failure you are unwilling to justify in writing.

Two rounds is normal. Splitting a class for cohesion adds a type that coupling then objects to; that is the loop working, not a problem with it.

**Every check applies to every class.** Running a check "over the model" means over each class in it, not over the two or three you happen to be thinking about. The failure mode is a check that is never run against a particular class at all, which reads exactly like a clean pass. Enumerate the classes and tick them off.

Observed on a real build: a catalog's `Offer` held both price and stock. The cohesion check was applied to `Store` and reported honestly, but never applied to `Offer` at all — so the walkthrough shipped a class whose own docstring read "one store's price **and** stock". The two fields have different writers (a store manager sets price; order fulfilment decrements stock) and different rates of change, which is the "start with the data" check failing too. Two checks would have caught it, and neither was run against that class.

A grep for `and` in the responsibility sentence finds candidates but decides nothing. In the same model, `Variant`'s sentence contained "and" inside a negation — "carries no price and no stock" — which is one idea, not two. Meanwhile `Store` failed the check without containing the word at all: "owns its listings, its category tree, its currency". List the classes, read each sentence, and judge it.

**The refactor is the lesson.** A walkthrough that shows a class being split because cohesion failed teaches far more than one that presents the split as if it were obvious from the start. Record what the model looked like *before* the fix; the phase prose is where that lands, as the trap the reader was about to fall into.

## Step 5 — Run SOLID over the finished diagram

Five checks, not a theory to recite. Run them in this order.

| Check | Quick test | Symptom |
|---|---|---|
| Single responsibility | Name the change that would force an edit. Two unrelated changes means two classes | The responsibility sentence needs an "and" |
| Open/closed | Pick one likely new feature. If it edits three classes, the design is closed to the wrong thing | A switch or if-chain over a type |
| Liskov | Re-check every inheritance arrow against substitution | A method that would have to throw, refuse, or do nothing |
| Interface segregation | Every implementer uses everything it promised | Empty method bodies |
| Dependency inversion | A high-level class names an interface, never a concrete low-level one | A class constructing its own collaborator |

**The same hard rule applies here.** A SOLID violation is refactored out, not recorded. Re-run the seven afterwards, because a SOLID fix moves classes around and the seven are sensitive to that.

**Calibration, given that the rule is being followed.** By the time you stop, the design should satisfy all five. What remains is the small set you *chose* not to fix, each with the cost written down — typically one, sometimes two, and each one a decision you can defend out loud.

**Zero remaining findings is suspicious in one specific way.** It is the right outcome if you refactored your way there, and the wrong one if you simply never looked. The distinction is visible in the walkthrough: a design that reached zero by refactoring has a phase showing the model *before* the fix. A design that reached zero by not looking has no such moment anywhere. If you cannot point at a single place the checks changed your model, you did not run them.

Two counter-rules. Do not add an interface with one implementer and no second in sight; that is indirection with no benefit. Do not split past the sentence test — single responsibility taken too far yields thirty two-method classes nobody can hold in their head.

## Step 6 — Name the patterns that fit, and the ones that do not

The repo's `design-patterns-expert` skill covers the full catalogue. What matters here is the signal that says a pattern applies, and the anti-signal that says it does not.

| Pattern | Use when | Do not use when |
|---|---|---|
| Strategy | One operation, several interchangeable rules | One rule, no sign of a second |
| Factory | Creation depends on a type value | One concrete class |
| Observer | Several listeners, and the source should not know them | One listener the source already holds |
| State | A lifecycle with many transitions | Three states and one guarded method |
| Singleton | Exactly one instance, genuinely | You only want convenient global access |
| Builder | Many optional fields | Three required fields |

Strategy is the one that answers "what if the rules change", which is the most common pressure a model faces after it ships.

One or two patterns is the right number for a model this size. A design carrying six is usually no longer following its requirements. **Naming the pattern you rejected is worth as much as naming the one you used** — "strategy for the rate, because a second rate is likely; not state for the ticket, because three statuses need only one guard" shows the pattern and its cost together.

## Where this feeds the walkthrough

Steps 1 and 2 become Sheet A and Sheet B. Step 2's class list and step 3's relationships determine the phase boundaries — a phase that cuts across a composition is usually cutting in the wrong place. Step 4's record of the seven principles is what Sheet D reports against, one entry per principle. Step 5's findings are what Sheet D and Sheet E are honest about. Step 6 fills the patterns table, including its declined column.

Note the ordering that matters most: steps 4 and 5 run **before** the implementation, on the model. Their findings are meant to change the design while changing it is still cheap. Writing the code first and then running the principles over it produces a report rather than a design, and the report will be flattering, because nobody finds a class worth deleting in code they just finished writing.
