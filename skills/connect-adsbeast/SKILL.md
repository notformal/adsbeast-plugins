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
