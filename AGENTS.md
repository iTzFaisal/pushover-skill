# Repository Guidance

- This repository contains one `pushover-notify` skill mirrored under `.claude/skills/pushover-notify/` and `.agents/skills/pushover-notify/`; keep each `SKILL.md` and `scripts/send_pushover.sh` copy synchronized.
- There is no package manifest, build system, test runner, lint configuration, CI workflow, or code generator. Do not invent project setup commands.
- For Bash helper changes, validate syntax with `bash -n <script>` and exercise the no-network path with `PUSHOVER_DRY_RUN=1 <script> --message "test"`.
- Live sends require `PUSHOVER_APP_TOKEN`, `PUSHOVER_USER_KEY`, `curl`, and an explicit user request; never put credentials in files, commits, or output. Read the adjacent `SKILL.md` before changing notification behavior.
- The helper posts to Pushover and treats only HTTP 200 with a JSON `status` of `1` as success. Priority `2` additionally requires `--confirm-emergency`, `--retry`, and `--expire`.
