---
name: connect-adsbeast
description: How to connect this plugin to an ADS Beast account and what to do when a tool reports that access was refused. Use this when a tool returns 401 or 403, when someone asks how to set the plugin up, when they are unsure which scopes a key needs, or when a tool that worked before starts refusing. The workflow is to read what the key actually carries with the whoami tool, compare that against the scope the failing tool needs, and say plainly which scope is missing so the right key can be created. Scopes are enforced fail-closed and cannot be widened from here, so the outcome is either a working call or a precise description of the key that would be needed.
---

# Connecting to ADS Beast

This plugin reads and writes one ADS Beast organization's data. Which
organization, and which parts of it, are both decided by the API key
supplied when the plugin was connected. Nothing in a conversation can widen
that.

## When to use

- A tool returned 401 or 403.
- Someone asks how to set this plugin up, or which key it needs.
- A tool that used to work has started refusing.
- Someone is deciding what scopes to put on a new key.

## Setting the key up

Installing the plugin does not give it a key. Until one is set, every
workspace tool answers 401 and the 401 message says how to fix it. Tell the
person these steps for their client; never ask for the key in the chat.

1. In ADS Beast an admin opens https://adsbeast.pro/api-keys, presses
   **New key**, ticks the scopes the work needs and copies the key. It starts
   with `absk_` and is shown once.
2. Give it to the client:
   - Codex: `codex mcp add adsbeast --url https://adsbeast.pro/api/mcp/workspace --bearer-token-env-var ADSBEAST_API_KEY`,
     then set `ADSBEAST_API_KEY` for good (macOS and Linux: add
     `export ADSBEAST_API_KEY=absk_...` to `~/.zshrc` or `~/.bashrc`;
     Windows PowerShell: `[Environment]::SetEnvironmentVariable("ADSBEAST_API_KEY", "absk_...", "User")`)
     and open a new terminal before starting Codex. `codex mcp list` shows
     `Bearer token` in the Auth column once it is right. A Codex plugin cannot
     carry the key itself, so this step is needed even after `codex plugin add`.
   - Claude Code: the plugin asks for the key when it is installed; to change
     it, reinstall the plugin.
   - Cursor, Gemini CLI, Windsurf: put the key in the `ADSBEAST_API_KEY`
     environment variable; the configs in this package read it from there.
     The package's `mcp.json` sends `Authorization: Bearer ${ADSBEAST_API_KEY}`
     too, but Codex drops that header, which is why Codex needs its own step.
3. Call `whoami`. It answers with the key's organization, scopes and the
   calls left this month.

## How access is decided

An ADS Beast key looks like `absk_...` and is created in the product under
API Keys. Creating one requires an admin account; a manager cannot mint a key.

Each key carries scopes, and every area is gated separately:

| Area | Scopes |
| --- | --- |
| Leads | `read:leads`, `write:leads` |
| Campaigns | `read:campaigns`, `write:campaigns` |
| Clients | `read:clients`, `write:clients` |
| Reports | `read:reports`, `write:reports` |
| Alerts | `read:alerts`, `write:alerts` |
| Tasks | `read:tasks`, `write:tasks` |
| Webhooks | `read:webhooks`, `write:webhooks` |
| Change proposals, previews, campaign drafts | `read:proposals`, `write:proposals` |
| Outreach | `read:outreach` |
| SEO and AI visibility | `read:seo` |

Enforcement is fail-closed. An area the key does not name is unreachable,
and areas outside this table, such as billing, settings and the platform
integrations, are not reachable with any integration key at all.

## Steps

1. When a tool reports that access was refused, call `whoami` first. It
   returns the key's name, its organization and the scopes it actually
   carries. This is the only reliable answer to what the key can do.
2. Compare what `whoami` reported against the area the failing tool belongs
   to, using the table above.
3. If the needed scope is absent, say so directly: name the scope, name the
   tool that needs it, and say that a new key has to be created in ADS Beast
   under API Keys by an admin. Do not retry the call.
4. If the scope is present and the call still fails, report the status the
   tool returned along with its message. A 404 on a record that exists means
   the record belongs to a different organization than the key does.
5. If `whoami` itself fails, the key is missing, wrong, expired or revoked.
   Say that rather than diagnosing scopes.
6. If the tool says the month's calls are used up, that is the plan's
   allowance, not the key. `whoami` is not counted and still answers: it
   shows the calls used, the calls included and the reset date. Pass those
   on with the link it gives, and do not retry until the reset.
7. If an audit or analytics tool answers 403 while the scope is present,
   the key is bound to a single client. Those tools need a key that is
   not bound to one client.

## Reporting the result

State which organization the key belongs to, which scopes it carries, and
which single scope is missing for the thing that was asked. Where a key
needs replacing, say which scopes the replacement should have, based on the
tools the work will actually use rather than requesting everything.

## Do not

- Do not ask anyone to paste an API key into the conversation. The key is
  configured where the plugin was connected, and a key in a chat transcript
  is a key that has leaked.
- Do not guess which scope a tool needs when `whoami` can be called.
- Do not retry a refused call unchanged. A 403 is a statement about the key,
  not a transient failure.
- Do not describe a refusal as an ADS Beast outage. The distinction matters:
  one is fixed by issuing a key, the other by waiting.
