# Pushover Notify Skill

An agent skill for sending text notifications to Pushover devices through the
Pushover Message API. The skill includes a credential-safe Bash helper for
normal, priority, and emergency notifications.

## Requirements

- A Pushover application token
- A Pushover user or group key

Configure credentials through environment variables. Never commit or print
their values:

```sh
export PUSHOVER_APP_TOKEN="your-application-token"
export PUSHOVER_USER_KEY="your-user-or-group-key"
```

## Quick Start

Install the skill from npx skills:

```sh
npx skills add iTzFaisal/pushover-skill
```

## Usage

Call `/pushover-notify` from your coding agent with an explicit request. In
Claude Code, OpenCode, or other supported agents, use the skill command directly:

```text
/pushover-notify Send a Pushover notification with the message "Backup finished" and title "Nightly backup".
```

### Optional Fields

Include optional fields in the agent request only when they are part of the
notification:

```text
/pushover-notify Send a Pushover notification:
message: "Build finished"
title: "CI"
device: "phone"
priority: 1
sound: "tugboat"
url: "https://example.com/build/123"
url title: "Open build"
```

The skill supports these notification options:

| Option                       | Description                                          |
| ---------------------------- | ---------------------------------------------------- |
| `--message TEXT`             | Required notification body                           |
| `--title TEXT`               | Notification title                                   |
| `--device NAME`              | Destination device; omitted means all active devices |
| `--priority LEVEL`           | `-2`, `-1`, `0`, `1`, or `2`; defaults to `0`        |
| `--sound NAME`               | Pushover notification sound                          |
| `--url URL`                  | Supplementary link                                   |
| `--url-title TEXT`           | Display title for the supplementary link             |
| `--ttl SECONDS`              | Lifetime for a transient non-emergency notification  |
| `--timestamp UNIX_TIMESTAMP` | Time associated with an earlier event                |
| `--retry SECONDS`            | Repeat interval for priority `2`                     |
| `--expire SECONDS`           | Expiry for priority `2`                              |
| `--callback URL`             | Optional priority-2 acknowledgement callback         |
| `--tags TAGS`                | Optional comma-separated priority-2 tags             |
| `--confirm-emergency`        | Required for priority `2`                            |

### Emergency Notifications

Priority `2` repeats until acknowledgement or expiry and can bypass quiet
hours. Ask your coding agent to send one only for a genuinely critical alert:

```text
/pushover-notify Send an emergency Pushover notification:
message: "Critical service failure"
priority: 2
retry: 60 seconds
expire: 3600 seconds
```

The agent must explain the behavior and request confirmation immediately before
sending unless the exact emergency notification was already confirmed.

## Repository Layout

The skill is mirrored for two agent environments:

| Environment | Skill directory                   |
| ----------- | --------------------------------- |
| Claude      | `.claude/skills/pushover-notify/` |
| Agents      | `.agents/skills/pushover-notify/` |

Each directory contains the skill instructions in `SKILL.md` and the helper at
`scripts/send_pushover.sh`. Keep both copies synchronized when making changes.

## Skill Behavior

- Notifications are sent only when the user explicitly requests one.
- Credentials are read from `PUSHOVER_APP_TOKEN` and `PUSHOVER_USER_KEY`.
- Secret values are not included in dry-run output or status messages.
- API validation errors are not silently retried.
- A successful API response means the notification was accepted and queued; it
  does not prove that a phone displayed it.
- The helper supports text notifications and common metadata, not attachments,
  encrypted messages, receipt lookups, or group management.

See the [Pushover Message API](https://pushover.net/api) for the full API
reference.
