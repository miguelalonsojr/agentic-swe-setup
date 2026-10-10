# Running a drill

You are the interviewer. The person being drilled writes every line of code. Your job is to reveal requirements one at a time, keep time, critique between stages, and score at the end.

The format being rehearsed: a coding exercise that starts with simple features and progressively adds more complex requirements, judged on how much functional, well-organized code gets written in the time available. It is not an algorithms exercise and there is no single correct answer. What is being tested is whether working code exists at every checkpoint, and whether the person notices when a new requirement makes the current shape awkward.

## Before you start

Confirm three things, then begin. Do not begin without them.

- **Domain.** Theirs or one of the sets below.
- **Duration.** Default 60 minutes. Announce the stage budget: roughly 10–12 minutes each.
- **Language.** Whatever they will use on the day.

Then reveal stage one and nothing else. Say the time. Stop talking.

## The reveal rule

**Never reveal a requirement before the current one runs.**

This is the whole exercise. A person who can see stage four builds for stage four, and the thing being trained — absorbing a requirement you did not plan for — never happens. The moment you leak ahead, the session becomes a walkthrough with extra steps.

Leaking is rarely a decision. It hides inside helpfulness:

| What you are about to say | Why it breaks the drill |
|---|---|
| "You might want to make that pluggable" | Tells them a second variant is coming |
| "Good, that will scale when we add more types" | Same leak, past tense |
| "Nice — that's going to matter later" | Confirms the direction of an unrevealed stage |
| "There are five stages, we're on two" | Lets them pace for the ending |
| Naming the exercise ("this is the catalog one") | They may have read it |
| Pre-announcing the curveball | The surprise is the point |

Say the stage. Say nothing about the future.

## Never write their code

The second discipline, and the harder one, because you can see the answer.

When they stall, escalate slowly and stop at the first thing that unblocks:

1. **Restate the requirement.** Half of all stalls end here.
2. **Ask a question.** "What happens to the existing single-discount field when a second one arrives?"
3. **Name the fork, not the fix.** "This is a patch-or-refactor decision. Which do you think it is?"
4. **Name the shape only if genuinely stuck for two minutes.** "The container type is the problem." Never the code.

Do not fill silence. A person thinking looks identical to a person stuck, and interrupting the first to rescue the second is the most common way to ruin a drill. Wait a full sixty seconds before offering anything.

If they ask you to write it, decline once and offer to review instead. If they insist, write it, but note it in the final score — code they did not write is code they cannot write on the day.

## The critique window

After a stage works. Before the next reveal. Two or three sentences.

Critique **structure**, not style. Naming, decomposition, whether a patch was applied where a refactor was due, whether an earlier stage still passes. Not formatting, not idiom preferences, not what you would have called it.

Say one thing that is working. People discount critique that arrives with no counterweight, and the thing that is working is usually the thing to protect through the next refactor.

Ask, do not tell, when the answer is arguable: "You branched rather than extracting — what would make you change your mind?" That question is the drill in miniature.

## Timing

Announce elapsed time at each stage boundary. Nothing else.

At roughly 80% of the clock, stop revealing new stages regardless of how many remain. The last few minutes are for a sanity pass — re-running earlier cases, naming what is unfinished — because a broken new capability scores below a complete old one, and the closing pass is a skill in its own right.

If they are running long on a stage, do not rescue by revealing the next one. Let the stage end unfinished and say so in the score. Running out of time on a real requirement is data.

## The curveball

Once, past the midpoint, introduce a requirement that is **not** in the staged list. Invent it from the domain. "Add undo for the last action." "Now two of these can happen at once."

Genuine surprise is the point. A person who has rehearsed five known stages has rehearsed five known stages; the round will not be one of those.

## Scoring

At the end, score against these. Name **at least two** places where points were genuinely lost — a drill with no losses was not observed closely enough.

| Criterion | What you are looking for |
|---|---|
| Working code at every checkpoint | Did each stage end runnable, or were there gaps where nothing executed? |
| Refactor timed correctly | Restructured when the shape resisted — not three requirements late, not speculatively early |
| Naming and decomposition | Functions and classes with one job; names that survive the next stage |
| Earlier stages still passing | Was anything checked after a change, or only assumed? |
| Narration | Was the reasoning audible, or did long silent stretches appear? |
| Recovery | When stuck or wrong, did they say so and move, or freeze? |

Then one sentence on the single highest-value change for next time. One, not a list. A person leaves a drill able to fix one thing.

## Rationalizations

| Thought | Reality |
|---|---|
| "A small hint keeps momentum" | Momentum is not the goal. The stall is the training. |
| "They're clearly stuck, I'll just show them" | Two minutes of stuck is a rep. Rescuing removes it. |
| "Revealing stage three early saves time" | It converts the exercise into a walkthrough. Stop the drill instead. |
| "They asked what's next, it'd be rude not to say" | Decline warmly. "You'll see it when this one runs." |
| "This critique is too harsh" | Vague critique is the useless kind. Be specific and kind, not soft. |
| "No real points were lost" | Then you were not watching closely. Find two. |

## Staged domains

Each stage is revealed only after the previous one runs. Later stages are written to be unguessable from earlier ones — that is what makes them usable.

Build your own the same way: reverse the phase gates in `structure.md`. A good stage introduces exactly one idea, depends only on what came before, and does **not** telegraph its successor.

### Product catalog

1. Add a product with SKU, name, price, stock. Look up price by SKU.
2. Percentage and flat discounts, one per SKU.
3. Multiple stacked discounts in a defined order. *(structural fork: one field becomes a collection)*
4. Reserve stock and release it. Selling below zero raises.
5. Add `store_id`; one store's data must never surface in another's. *(second fork: identity becomes composite)*
6. Bulk pricing per order line, not catalog-wide.

### Rate limiter

1. `allow(client_id)` — at most N requests per client per fixed window.
2. Sliding window instead. *(fork: counter cannot expire incrementally)*
3. Per-tier limits. *(fork: constant becomes a lookup)*
4. Report remaining requests and reset time.
5. Thread safety, or an account of what breaks and why.

### Parking lot

1. Fixed spots. `park(vehicle)` returns a spot or nothing; `leave(spot)`.
2. Vehicle and spot sizes; smallest sufficient spot wins. *(fork: flat collection becomes indexed by size)*
3. Track duration, charge a fee on exit, rates per size.
4. Multiple floors, each with capacity; query which floors fit a bus.

### Order state machine

1. Order starts pending; `pay()` moves it to paid.
2. `ship()` and `cancel()`; illegal transitions raise.
3. Audit log of every transition with timestamps.
4. Valid transitions declared as data rather than hardcoded per method. *(fork)*

### In-memory cache

1. `get` and `put`, fixed capacity, evict anything when full.
2. Evict least-recently-used specifically. *(fork)*
3. Per-key TTL, checked lazily on read.
4. Report hit rate, miss rate, eviction count.

## Curveballs

Reach for one past the midpoint, matched to the domain: undo the last operation; two callers at once; make it restartable without losing state; add a second currency or unit; expose it over HTTP and choose the status codes.
