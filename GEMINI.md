# ADS Beast

This extension connects two MCP servers run by ADS Beast.

- `adsbeast`: the user's own ADS Beast workspace. Clients, campaigns across
  the connected ad platforms, leads with attribution, alerts, tasks, reports,
  change proposals and campaign drafts. Needs the API key set in the
  extension settings.
- `ad-spec-guard`: reference checks that need no account. Platform character
  limits, creative specs, statistical gates, UTM tagging, policy pre-checks.

## How to work with the workspace server

1. Check the connection first. Call `whoami` before any other workspace
   tool. It reports the organization and the scopes of the key. If it fails,
   the key is missing or revoked: say so and stop. Do not ask the user to
   paste a key into the conversation; it is set with
   `gemini extensions config adsbeast`.
2. When the conversation is about one client, read `get_agency_kit` for that
   client before giving advice. It carries the goals, the last 30 days of
   results and the write policy.
3. Amounts are in the currency of the ad account they came from. Name the
   currency next to every figure. Never add up figures from accounts in
   different currencies and never assume dollars.
4. Never retry a failed create. If `create_campaign_draft`,
   `propose_campaign_change`, `create_webhook` or a non-dry-run
   `push_lead_outcomes` errors or times out, look first with
   `list_campaign_drafts`, `list_proposals` or `list_webhooks`, then report.
5. Confirm before anything that affects spend. Show the exact change with
   current value, new value and currency, and wait for a clear yes.
6. This server cannot approve, publish or activate anything. A proposal
   waits for a person in ADS Beast. A campaign draft is published by a person
   in the campaign builder and is uploaded paused. Say that plainly; do not
   report a change as done.
7. An empty list is not a clean bill of health. Report it as nothing
   returned and say what was not checked.

## Workflows

The `skills/` directory holds step-by-step workflows. Use the matching one
instead of improvising the order of calls:

| Request | Skill |
| --- | --- |
| Audit an account | `account-audit` |
| Find wasted spend | `wasted-spend-hunt` |
| Search terms and negative keywords | `search-terms-negatives` |
| Create a campaign | `campaign-launch` |
| Budget pace | `budget-pacing-check` |
| Weekly status | `weekly-report` |
| Is tracking working | `conversion-tracking-check` |
| Leads and outcomes | `lead-pipeline-review` |
| A tool answered 401 or 403 | `connect-adsbeast` |

The same workflows are available as commands: `/adsbeast:audit`,
`/adsbeast:wasted-spend`, `/adsbeast:launch`, `/adsbeast:pacing`,
`/adsbeast:weekly-report`, `/adsbeast:tracking-check`, `/adsbeast:leads`.

## Ad copy and specs

For any ad text, creative size or "is this enough data to decide" question,
call the `ad-spec-guard` tools instead of answering from memory. Platform
limits change, and a remembered limit produces copy the platform rejects.
