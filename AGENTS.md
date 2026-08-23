# Repository instructions

## Project

- This repository manages a Proxmox home lab with OpenTofu.
- Treat infrastructure changes as potentially destructive.
- Keep documentation consistent with behavior and supported versions.

## Efficient workflow

- Inspect the requested diff or files before exploring the repository.
- Read only changed files and direct dependencies needed to answer correctly.
- Search for symbols or references before opening broad directory trees.
- Do not reread unchanged content. Stop investigating when evidence is enough.
- For reviews, discuss only introduced changes and direct consequences.
- Do not run unrelated checks or propose unrelated cleanup.

## Safety

- Never expose, commit, or print credentials, API tokens, private keys, state,
  plan files, populated `terraform.tfvars`, or sensitive API responses.
- Never run `tofu apply`, `tofu destroy`, import, or state mutation commands
  unless the user explicitly requests the exact operation and confirms scope.
- Do not make live Proxmox or infrastructure changes during code review.
- Preserve existing user changes. Avoid destructive Git commands.
- Prefer least privilege, explicit versions, safe defaults, and predictable
  resource lifecycle behavior.

## OpenTofu changes

- Run `tofu fmt -check -recursive` after changing `.tf` files when available.
- Run `tofu validate` only in affected initialized root modules. Do not run
  `tofu init` merely to validate unless dependency downloads are authorized.
- Review plans before any apply. Call out replacement, deletion, downtime,
  state migration, ordering, and concurrency risks.
- Keep provider constraints and `.terraform.lock.hcl` consistent.

## Code review rules

- Prioritize real bugs and operational risks over style preferences.
- Ignore formatter/linter-only issues unless they cause a concrete failure.
- Require a specific failure scenario; avoid speculative warnings.
- Check secrets, privileges, idempotency, validation, dependencies, unsafe
  defaults, state/lifecycle effects, unexpected recreation, and downtime.
- Do not duplicate findings or praise routine code.
- Each finding must name severity, impact, and a practical fix.
- Prefer an inline comment on the smallest relevant changed line range.

## Change suggestions and commits

- Make suggestions executable: name the file and location, and provide an exact
  replacement, GitHub suggestion block, or compact patch when practical.
- Include the smallest useful validation step.
- When asked for commits, group changes into independent reviewable units and
  propose concise Conventional Commit subjects. Do not claim a commit exists
  unless it was actually created.

## Compact communication

- Lead with the result, finding, or decision. No greeting or task restatement.
- Use concise technical language, short paragraphs, and compact bullets.
- Omit filler, praise, narration of obvious steps, and repeated summaries.
- Give one explanation per point. Do not repeat the same fact in new wording.
- For simple outcomes, answer in a few lines. Expand only when correctness,
  safety, ambiguity, or the user explicitly requires detail.
- Preserve exact code, commands, paths, identifiers, and error messages.
- Match the user's language when practical; default repository prose to English.
- Concision must never hide a risk, failed check, assumption, or uncertainty.
