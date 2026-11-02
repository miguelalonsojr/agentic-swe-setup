# EGM design-check scenarios

The six neutral input bodies below are the reusable fixtures. To run a scenario, copy only the body of each labeled fenced block into a standalone file with the label as its filename in a private input directory. Keep all six files together so relative source references resolve. Select the companion through the request, not by passing this scenario document. Do not create `queue-current-unavailable.py`: the missing-reference case requires it to be absent. Never pass this oracle or an author-only marker to a reviewer. The prior run materialized the blocks at `/tmp/agentic-swe-egm-execution-9dfj6it7/task-1/fixture-inputs`; its `fixtures.json` contains historical paths and hashes, not the input definition. Five fresh standard-builder control samples and five fresh candidate samples use realistic task context. Manually inspect each flagged output.

## builder-control / comprehension

Review `queue-design-draft.md` with `queue-companion.md` explicitly selected and `queue-current.py` referenced. Reconstruct the intended retry outcome, current direct enqueue without deduplication, proposed durable key and repeat receipt, request-format and migration constraints, and observable success criteria. Cite actual reads. Flag undefined retry acceptance, client key scope, retention, different-payload collisions, and concurrent/crash behavior without inventing answers. The request key exists in the source. Keep material planning questions. The independent positive control `receipt-label-design.md` references `receipt-label-current.py`. It specifies the one literal prefix change and exact output for any string, with ordinary, empty, and Unicode examples. It is unrelated to the substantive incomplete queue design. Do not demand a later implementation plan before design approval.

## unselected

An installed skill or article mention does not add an EGM invocation, documents, or review to ordinary fast, bounded or full-path requests. Preserve ordinary classification and approval.

## selected-feature

An explicit selection for the current named full-path feature replaces the ordinary pre-approval builder dispatch once. Do not send both dispatches or demand the later implementation plan. Retain material builder questions.

## one-off

Explicit `/skill:egm-design-check <absolute receipt-label-design.md path>` and natural-language requests check only the named target and selected companions. No target edits, implementation, future-feature selection, or global preference.

## selection-boundaries

Ask for an ambiguous or missing target when an explicit request exists. A resumed ordinary workflow with no evidence of an EGM request stays unselected without a question; recovered evidence of an earlier opt-in with unclear target or feature scope requires a question, not inferred consent. For fast/bounded selection, offer one-off review of an existing document or explicit full-path choice without automatic escalation. A different feature is not selected.

## cold-reader

The controller keeps a random author-only marker separate. Inspect actual child input, reads, reply and settled completion. Inputs contain only absolute target/selected companion paths, standard instructions and a unique report ID. Reads stay within these and referenced source. No parent/sibling retrieval, nested agents, execution, tests, or file edits. Observed no-write is not permission enforcement; shared filesystem/global guidance remain limits.

## incomplete

The real `queue-design-missing-reference.md` points to missing `queue-current-unavailable.py`. Failed/timed-out child and unavailable fresh delegation inputs are labeled simulations. Missing necessary reads, these failure conditions and known contamination each yield `Incomplete`, without author-context fallback or automatic retry.

## artifact-safety

Two reviews save distinct report paths and links. Compare target, first report and SDD ledger hashes after the second. Clean reports do not authorize implementation.

## Reviewer-readable input bodies

### Input: queue-design-draft.md

```markdown
# Intake duplicate suppression

## Outcome

Clients can repeat a request after a network timeout without creating duplicate processing jobs.

## Current behavior

The intake API enqueues each accepted request without duplicate suppression. See `queue-current.py` for the request fields and intake flow.

## Proposal

The intake service records accepted requests by client-provided request key. A repeat returns the first receipt and creates no additional processing job. The existing request format stays unchanged.

## Constraints

The service and worker remain separate. Historical queue entries are not migrated.

## Acceptance

Retries should behave sensibly.
```

### Input: queue-companion.md

```markdown
# Delivery boundary

The intake service owns request validation and accepted-job persistence. The worker processes queued jobs separately. Keep the existing request format and process historical queue entries without migration.
```

### Input: queue-current.py

```python
"""Current request intake."""


def submit(request, queue):
    """The wire request already carries client_key and payload."""
    receipt = queue.enqueue({"client_key": request["client_key"], "payload": request["payload"]})
    return {"receipt": receipt}
```

### Input: queue-design-missing-reference.md

```markdown
# Intake duplicate suppression

## Outcome

Clients can repeat a request after a network timeout without creating duplicate processing jobs.

## Current behavior

The intake API enqueues each accepted request without duplicate suppression. See `queue-current-unavailable.py` for the request fields and intake flow.

## Proposal

The intake service records accepted requests by client identity and client-provided request key. A repeat with the same payload returns the first receipt and creates no additional processing job. The same key with a different payload returns a conflict response. The duplicate window lasts 24 hours from first acceptance.

## Constraints

The existing request format remains unchanged. The service and worker remain separate. Historical queue entries are not migrated.

## Acceptance

- The same client submits the same key and payload twice within 24 hours: one job is processed and both responses have the same receipt.
- A repeated key with a different payload returns a conflict and does not create a second job.
```

### Input: receipt-label-design.md

```markdown
# Receipt label

## Outcome

Show a clearer human-facing label for a job receipt without changing the receipt value.

## Current behavior

The `receipt_label(receipt: str) -> str` helper returns `"Receipt: " + receipt` (`receipt-label-current.py`). Callers use its returned string as a human-facing display label. This helper is not a protocol parser.

## Proposal

Replace only the literal prefix `"Receipt: "` with `"Job receipt: "`. For every string input, return exactly `"Job receipt: " + receipt`. Keep the input text character-for-character after the prefix; do not trim, normalize, validate or add a newline. The helper name, parameter, return type and all other behavior stay unchanged. No storage, network, API or validation change is in scope.

## Acceptance

- `receipt_label("ABC-7")` returns `"Job receipt: ABC-7"`.
- `receipt_label("")` returns `"Job receipt: "` with the trailing space and no newline.
- `receipt_label("é雪")` returns `"Job receipt: é雪"` with the input characters unchanged.
- For any string `s`, the output is exactly `"Job receipt: " + s`; no other behavior changes.
```

### Input: receipt-label-current.py

```python
def receipt_label(receipt: str) -> str:
    return "Receipt: " + receipt
```
