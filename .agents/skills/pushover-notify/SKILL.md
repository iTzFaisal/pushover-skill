---
name: pushover-notify
description: Send notifications to the user's mobile devices through Pushover. Use this skill whenever the user explicitly asks to notify, alert, ping, message, or send a status update to their phone or mobile device via Pushover, including requests phrased as "let me know on my phone" or "send me a push notification." Do not wait for the user to mention the skill name. Keep credentials out of files and never claim delivery without verifying the API response.
compatibility: Requires Bash, `curl`, and the environment variables `PUSHOVER_APP_TOKEN` and `PUSHOVER_USER_KEY` for live sends.
---

# Pushover Notifications

Use this skill for an explicit request to send a notification through Pushover. Do not send unsolicited notifications merely because a task finished; the user must ask for the notification as part of the request or in a follow-up.

## Credential Safety

- Read the application token from `PUSHOVER_APP_TOKEN`.
- Read the destination user or group key from `PUSHOVER_USER_KEY`.
- Never ask the user to paste either secret into chat when environment variables can be configured instead.
- Never write credentials to a file, commit them, include them in an output artifact, or print their values in a command or status message.
- If either variable is missing for a live send, stop and explain which variable must be configured. Do not claim that a message was sent.
- A dry run may be performed with `PUSHOVER_DRY_RUN=1`; dry runs do not require credentials and must not make a network request.

## API Contract

The Message API is documented at <https://pushover.net/api>.

- Send an HTTPS `POST` request to `https://api.pushover.net/1/messages.json`.
- The required form fields are `token`, `user`, and `message`.
- Use `application/x-www-form-urlencoded` fields for text messages. `curl --data-urlencode` handles punctuation and Unicode safely.
- A successful request has HTTP status `200` and a JSON body with `status: 1`. Report the returned `request` identifier when available.
- A `4xx` response or a JSON response whose `status` is not `1` means the request is invalid or the account is over quota. Do not retry the same request without changing the cause.
- A connection failure or `5xx` response may be retried after waiting at least 5 seconds. Retry at most once unless the user explicitly asks for more attempts, because an acknowledged request can otherwise produce duplicate notifications.

Pushover limits message bodies to 1024 UTF-8 characters, titles to 250 characters, supplementary URLs to 512 characters, and URL titles to 100 characters. Keep messages concise and surface an API validation error instead of silently truncating user content.

## Compose the Notification

Before sending, derive the following from the user's request:

- `message`: Required notification body. Preserve the user's meaning, but keep it concise.
- `title`: Optional title. If omitted, Pushover uses the application name.
- `device`: Optional device name. Omit it to deliver to all active devices for the destination key.
- `priority`: Default to `0` (normal). Use `-1` or `-2` only when the user requests a quiet or no-alert notification. Use `1` only when the user clearly requests high priority.
- `sound`: Optional supported sound name. Omit it to use the recipient's default.
- `url` and `url_title`: Optional supplementary link and its display title.
- `ttl`: Optional positive lifetime in seconds for a transient message. Do not use it for emergency priority.
- `timestamp`: Optional Unix timestamp when the notification represents an earlier event.

Do not invent a title, priority, device, URL, or sound when the user did not request one. Normal priority is the safe default.

## Emergency Notifications

Priority `2` repeatedly alerts the user until it is acknowledged and is intended for genuinely critical on-call situations. Treat it as a consequential action:

1. Explain that priority `2` bypasses quiet hours and repeats until acknowledgement or expiry.
2. Ask for confirmation immediately before sending unless the user has already explicitly confirmed the exact emergency notification in the current turn.
3. Require `retry` in seconds, with a minimum of `30`, and `expire` in seconds, with a maximum of `10800` (3 hours).
4. Send `priority=2`, `retry`, and `expire` together. An optional public `callback` URL and `tags` may be included only when the user supplies them.
5. Report the returned `receipt` and `request` identifiers. A priority-2 response should include a receipt that can be used with the receipts API.

High priority `1` bypasses quiet hours but does not repeat until acknowledgement. Warn the user when choosing it, and do not upgrade a normal request to high or emergency priority on your own.

## Send a Text Notification

Use the bundled Bash helper instead of reconstructing request handling each time. Resolve the directory containing this `SKILL.md` and invoke the helper from that directory; do not assume the current project directory is the skill directory:

```sh
scripts/send_pushover.sh --message "Backup finished" --title "Nightly backup"
```

Add optional arguments only when requested:

```sh
scripts/send_pushover.sh \
  --message "Build finished: https://example.com/build/123" \
  --title "CI" \
  --priority 1 \
  --sound tugboat \
  --url "https://example.com/build/123" \
  --url-title "Open build"
```

For a dry run, set `PUSHOVER_DRY_RUN=1` before invoking the helper. The helper must show the endpoint and field names without showing secret values and must not contact the API.

If the helper is unavailable, use the equivalent request directly, keeping the token and user values in environment-variable expansions rather than literal text:

```sh
curl --silent --show-error --request POST \
  --url https://api.pushover.net/1/messages.json \
  --data-urlencode "token=${PUSHOVER_APP_TOKEN}" \
  --data-urlencode "user=${PUSHOVER_USER_KEY}" \
  --data-urlencode "message=${MESSAGE}"
```

When optional fields are used, add one `--data-urlencode` field per parameter. Do not use `GET`, send credentials in a URL query string, disable TLS verification, or log the expanded request.

## Attachments and Unsupported Requests

The helper is intentionally limited to text notifications and common metadata. If the user requests an image attachment, encrypted message, receipts lookup, group management, or another Pushover API, do not pretend the helper supports it. Consult the relevant section of the official API documentation and explain the additional request format before proceeding.

## Verify and Report

After a live send:

1. Inspect the HTTP status and JSON response, including `status`, `errors`, `request`, and `receipt` when present.
2. Report that the API accepted and queued the notification only when HTTP `200` and `status: 1` are both present. Queued is not the same as proof that the phone displayed it.
3. On failure, quote the safe error text from `errors` without exposing credentials, then state whether the request was not retried or was retried after the required delay.
4. Keep the final report concise: message summary, destination scope if relevant, priority, and API request/receipt identifiers.
