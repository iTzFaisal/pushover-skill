# Pushover Notify Skill

An agent skill for sending text notifications to Pushover devices through the
Pushover Message API. The skill includes a credential-safe Bash helper for
normal, priority, and emergency notifications.

## Requirements

- Bash
- `curl` for live sends
- A Pushover application token
- A Pushover user or group key

Configure credentials through environment variables. Never commit or print
their values:

```sh
export PUSHOVER_APP_TOKEN="your-application-token"
export PUSHOVER_USER_KEY="your-user-or-group-key"
```

## Repository Layout

The skill is mirrored for two agent environments:

| Environment | Skill directory |
| --- | --- |
| Claude | `.claude/skills/pushover-notify/` |
| Agents | `.agents/skills/pushover-notify/` |

Each directory contains the skill instructions in `SKILL.md` and the helper at
`scripts/send_pushover.sh`. Keep both copies synchronized when making changes.

## Usage

Run the helper from the relevant skill directory. From this repository's root:

```sh
.claude/skills/pushover-notify/scripts/send_pushover.sh \
  --message "Backup finished" \
  --title "Nightly backup"
```

The helper sends a `POST` request to
`https://api.pushover.net/1/messages.json`. A send is reported as successful
only when the API returns HTTP `200` and a JSON response with `status: 1`.

### Optional Fields

Use optional fields only when they are part of the notification request:

```sh
.claude/skills/pushover-notify/scripts/send_pushover.sh \
  --message "Build finished" \
  --title "CI" \
  --device phone \
  --priority 1 \
  --sound tugboat \
  --url "https://example.com/build/123" \
  --url-title "Open build"
```

Supported options are:

| Option | Description |
| --- | --- |
| `--message TEXT` | Required notification body |
| `--title TEXT` | Notification title |
| `--device NAME` | Destination device; omitted means all active devices |
| `--priority LEVEL` | `-2`, `-1`, `0`, `1`, or `2`; defaults to `0` |
| `--sound NAME` | Pushover notification sound |
| `--url URL` | Supplementary link |
| `--url-title TEXT` | Display title for the supplementary link |
| `--ttl SECONDS` | Lifetime for a transient non-emergency notification |
| `--timestamp UNIX_TIMESTAMP` | Time associated with an earlier event |
| `--retry SECONDS` | Repeat interval for priority `2` |
| `--expire SECONDS` | Expiry for priority `2` |
| `--callback URL` | Optional priority-2 acknowledgement callback |
| `--tags TAGS` | Optional comma-separated priority-2 tags |
| `--confirm-emergency` | Required for priority `2` |

### Dry Run

Use dry run mode to inspect the endpoint and field names without credentials
or a network request:

```sh
PUSHOVER_DRY_RUN=1 \
  .claude/skills/pushover-notify/scripts/send_pushover.sh \
  --message "Test notification"
```

### Emergency Notifications

Priority `2` repeats until acknowledgement or expiry and can bypass quiet
hours. Use it only for genuinely critical alerts and only after explicit
confirmation immediately before sending. The helper requires:

- `--confirm-emergency`
- `--retry` of at least 30 seconds
- `--expire` between 1 and 10,800 seconds

For example:

```sh
.claude/skills/pushover-notify/scripts/send_pushover.sh \
  --message "Critical service failure" \
  --priority 2 \
  --retry 60 \
  --expire 3600 \
  --confirm-emergency
```

`--ttl` cannot be combined with priority `2`. The helper also rejects
`--retry`, `--expire`, `--callback`, and `--tags` for other priorities.

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

## Validation

There is no package manager, build system, or test runner in this repository.
Run the supported checks from the repository root:

```sh
bash -n .claude/skills/pushover-notify/scripts/send_pushover.sh
PUSHOVER_DRY_RUN=1 \
  .claude/skills/pushover-notify/scripts/send_pushover.sh \
  --message "test"
cmp -s \
  .claude/skills/pushover-notify/SKILL.md \
  .agents/skills/pushover-notify/SKILL.md
cmp -s \
  .claude/skills/pushover-notify/scripts/send_pushover.sh \
  .agents/skills/pushover-notify/scripts/send_pushover.sh
```

Live sends require an explicit request and valid credentials. Do not use live
credentials for validation unless a real notification is intended.
