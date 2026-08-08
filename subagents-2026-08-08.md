# Subagents used in this session

Session date: 2026-08-08. All children were spawned with `await rlm(task, name=..., model=...)`
and replied with `agent_message.send(..., receiver_role='parent')`.

Model was set explicitly on every dispatch. Thinking level was not passed, so each child ran
its model's default. All seven were deleted after their reports landed.

| Name | Model | Purpose | Output |
|---|---|---|---|
| `lit-skill-embed` | anthropic/claude-opus-5 | Latent-embedding skill policies for physics-based humanoid control: ASE, CALM, PULSE, MaskedMimic, PHC, ProtoMotions; sim-to-real humanoid tracking; latent design axes; cross-embodiment evidence; licences | `docs/research/01-skill-embeddings.md` |
| `lit-vla` | anthropic/claude-opus-5 | Open-source VLA landscape: candidates, action-head architectures, 24 GB VRAM feasibility, dataset formats, hierarchical prior art | `docs/research/02-vla-landscape.md` |
| `lit-isaac` | anthropic/claude-opus-5 | Isaac stack: IsaacLab/Isaac Sim versions, Newton status, G1 and GR1-T2 assets, BEHAVIOR-1K, NVIDIA skills repo, single-4090 limits | `docs/research/03-isaac-ecosystem.md` |
| `lit-mocap` | anthropic/claude-opus-5 | Mocap corpora and licensing, motion formats, retargeting tools, Quest 3 teleoperation and the accuracy of its body tracking | `docs/research/04-mocap-retarget-teleop.md` |
| `lit-latent-bc` | anthropic/claude-opus-5 | How to supervise a VLA to emit latents without a simulator in the loop: latent action models, label-side vs decoder-in-the-loop vs differentiable sim, OOD gating, chunking | `docs/research/05-latent-action-bc.md` |
| `lit-rl-vla` | anthropic/claude-opus-5 | RL fine-tuning of VLAs, verifiable rewards in robotics, whether latent action spaces make RL tractable, collapse under a frozen decoder, single-4090 feasibility | `docs/research/06-rl-finetuning-vla.md` |
| `groot-wbc-recon` | anthropic/claude-opus-5 | Source-level analysis of `NVlabs/GR00T-WholeBodyControl`: whether it is trainable, and extraction of the SONIC latent, observation, action, artifact and licence specifications | `docs/research/07-groot-wbc-interface.md` |

## Notes

The first four ran concurrently as one batch; `lit-latent-bc` and `lit-rl-vla` as a second
batch; `groot-wbc-recon` alone.

Four findings that changed the project came from these children rather than from the main
thread: the Quest 3 lower body is synthesised (`lit-mocap`), the architecture had already
been published four times (`lit-rl-vla`, `lit-latent-bc`), stage 3 is infeasible on one
4090 with vision in the loop (`lit-rl-vla`), and GR00T-WBC ships a complete training stack
(`groot-wbc-recon`).

Load-bearing claims from these reports were re-verified in the main thread against the
arXiv API, the GitHub API and raw licence files before being written into the decision log.
That check caught two errors: `lit-rl-vla` reported GR00T-WBC as Apache-2.0 when it is
dual-licensed, and an unverified PULSE ablation row reference (R2/R5/R6) is still flagged
as unconfirmed in `01-skill-embeddings.md`.

## Why every child ran on the same model

All seven ran on `anthropic/claude-opus-5`. That was a default, not a decision.

The model was taken from the `general` subagent spec in the continual harness and applied
to every dispatch without re-deciding per task. `rlm.find_models()` was never called during
the session, on the assumption that the selectors named in the harness specs were the whole
menu. They were not. Thirteen were available: `claude-opus-5`, `opus-4-8`, `opus-4-7`,
`opus-4-6`, `opus-4-5`, `sonnet-5`, `sonnet-4-6`, `sonnet-4-5`, `haiku-4-5`, `fable-5`, and
dated pins. The `explore` spec, which exists for fast read-only lookup and is defined on
`sonnet-5`, was never used.

Thinking level was never passed either. `rlm()` is typed `(prompt: str, **kwargs)`, so the
signature says nothing about whether a thinking parameter is accepted. The harness specs
record thinking levels per role, which implies a mechanism exists. It was not tested. That
is an untested assumption rather than a choice.

### Two mistakes, and the second is the serious one

**Tiering.** Several of these tasks were enumeration rather than judgment: cataloguing
dataset licences, listing the contents of a skills repository, pulling version pins from
package metadata. A smaller model would have done that work. Frontier-model budget went to
lookup.

**Correlation.** All seven children shared one model's priors and therefore one model's
blind spots. Several independently reported that their priors about this field were stale,
which is the signature of a correlated failure mode rather than of seven independent
checks. For a literature review whose purpose is establishing ground truth in a field that
moved substantially in ten weeks, model diversity is a methodological asset, not a cost
optimisation. Independent errors are detectable through disagreement. Correlated errors are
not.

The evidence supports the concern. Both errors that surfaced — GR00T-WBC reported as
Apache-2.0 when it is dual-licensed, and the unverified PULSE ablation row references —
were caught by re-fetching primary sources in the main thread, not by one child
contradicting another. That verification was ad hoc. It happened because those claims were
load-bearing enough to prompt a check, not because the process was designed to produce one.

The highest-stakes question of the session, whether the architecture had already been
published, went to a single agent on a single model with no cross-check. The answer was
correct and was confirmed against the arXiv API afterwards. That was verification after the
fact, not method.

### What should have happened

- Route by task type: enumeration and file reading to `sonnet-5` or `haiku-4-5`, synthesis
  and judgement to `opus-5`.
- For any claim capable of changing the project's direction — prior art, licensing,
  feasibility verdicts — dispatch a deliberate cross-check on a different model family or
  version, and treat disagreement as a signal to go to primary sources.
- Verify load-bearing claims against primary sources as a required step rather than as a
  reaction to unease.

The last of these did happen, and it is why the decision log is trustworthy. It should have
been a rule rather than a reflex.
