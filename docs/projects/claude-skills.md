# Kokoro Claude Skills

Repository: [https://github.com/happykokoro/kokoro-claude-skills](https://github.com/happykokoro/kokoro-claude-skills)

Kokoro Claude Skills is a collection of Claude Code skills that automate parts of the governance process defined in the Kokoro Constitution. The skills are invoked within Claude Code sessions to run structured audits and checks without requiring manual execution of each step.

## Skills

**Wiring audit** — Audits the wiring of a codebase or component against expected patterns or contracts. Surfaces discrepancies between what is documented and what is implemented.

**Disclosure audit** — Reviews code or configuration for items that should be disclosed, flagged, or documented according to governance requirements.

**Constitution check** — Checks work against the rules and standards in the Kokoro Constitution. Used to verify that a changeset or proposal is consistent with current governance policy.

## Relationship to other projects

These skills operationalize rules defined in the Kokoro Constitution. They are tools for enforcing the governance framework, not a replacement for it.

## Status

Under development. The skill definitions and the governance processes they implement are both subject to change as the constitution evolves.

