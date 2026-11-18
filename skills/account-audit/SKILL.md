---
name: account-audit
description: Workflow for auditing one client's advertising account through the ADS Beast workspace server. Use this when someone asks for an audit, a health check, a review of an account or client, or asks what is wrong with their ads. The workflow checks the connection with whoami, reads the client and its connected accounts, the agency kit with the last 30 days of results, the campaign list, open alerts and pending proposals, then reports findings by severity with the evidence for each and a list of what could not be checked. Findings that need a change go through propose_campaign_change after the person confirms, never as a direct edit.
---

# Account audit

An audit of one client: what is running, what it costs, what it returns and
what is broken. The output is a short list of findings a person can act on,
each with the number behind it, plus an honest list of what this server
could not show.

## When to use

- "Audit this account", "health check", "what is wrong with our ads".
- A new client was connected and nobody has looked at the account yet.
- Before a planning conversation about budget or structure.

## Steps

1. Call `whoami`. Confirm the organization and that the key carries
   `read:clients`, `read:campaigns` and `read:alerts`. Missing scopes limit
   the audit; say which parts will be skipped.
2. Pick the client. If the person did not name one, call `list_clients` and
   ask. Do not audit "everything" in one pass.
3. Call `get_client` with that `client_id`. Note the connected advertising
   accounts, the budget and the goals. A client with no connected account
   cannot be audited from here: say so and stop.
4. Call `get_agency_kit` with the same `client_id`. It carries the last 30
   days of results per account and campaign, leads by stage, the KPI goals
   and the write policy. Read the write policy: it says whether changes are
   allowed at all for this client.
5. Call `list_campaigns` with the `client_id`. Walk the pages while
   `has_more` is true. Group by platform and status.
6. For campaigns that look off (spend without results, a budget far from
   the rest, a status that contradicts delivery), call `get_campaign` for the
   detail.
7. Call `list_alerts` with the `client_id` and `is_resolved` false. An open
   critical alert is a finding by itself.
8. Call `list_proposals` with the `client_id`. A change that is already
   waiting for approval must not be proposed again.
9. Call `lead_pipeline_stats` with the `client_id` if the key has
   `read:leads`. Results that stop at "lead" and never reach a later stage
   are a finding about lead quality, not about traffic.

## What to look for

- Spend with no conversions over the window, per campaign.
- Cost per result far above the goal in the agency kit.
- Active campaigns on an account with open delivery or billing alerts.
- Budgets concentrated in campaigns that return the least.
- Campaigns that are enabled but show no spend: check alerts before calling
  them idle.
- Leads piling up in the first stage: nobody is working them, or they are
  junk.

Judge thin data honestly. A campaign with a handful of clicks has not
proved anything either way; say the sample is too small instead of calling
it a loser. If the ad-spec-guard plugin is installed, its
decision-readiness check is the right gate before a pause is suggested.

## Reporting the result

- Client, platforms covered, the window the figures refer to.
- Findings ordered critical, warning, note. Each one: what was observed, the
  figure with its currency, the campaign it concerns, the suggested action.
- A separate list: not checked, and why (scope missing, account not
  connected, data not exposed by this server). Search terms, keyword-level
  quality and creative-level results are not exposed by this server today;
  do not imply they were reviewed.
- If the person wants a suggested change made: confirm it with them, then
  call `propose_campaign_change` with the reason and the figures.

## Safety rules

These apply to every step above.

1. Check the connection first. Call `whoami` before anything else. If it
   fails, the key is missing, wrong or revoked: say so and stop. If it works,
   read the scopes it reports and do not call a tool whose scope is absent.
2. Amounts are in the currency of the ad account they came from. Never put a
   dollar sign on a figure because it is a number, never add up figures from
   accounts in different currencies, and name the currency next to every
   amount you report. If the currency is not in the data, say it is unknown.
3. Never retry a failed create. If `create_campaign_draft`,
   `propose_campaign_change`, `create_webhook` or a non-dry-run
   `push_lead_outcomes` returns an error or times out, do not send it again.
   Look first (`list_campaign_drafts`, `list_proposals`, `list_webhooks`) to
   see whether the record exists, then report what you found. A repeated
   create is how duplicates and double changes happen.
4. Confirm before anything that affects spend. Show the person the exact
   change (campaign, current value, new value, currency, reason) and wait for
   a clear yes in the conversation before calling `propose_campaign_change`
   or creating a draft with a budget. Their yes creates a proposal or a
   draft; it does not change the ad account.
5. This server cannot approve, publish or activate. A proposal waits for a
   person in ADS Beast, a draft is published by a person in the campaign
   builder, and a published campaign is uploaded paused. Say this plainly
   instead of reporting a change as done.
6. Empty is not healthy. An empty list can mean no access, no connected
   account or no synced data. Report it as "nothing returned" and name what
   was not checked. Do not turn a missing figure into zero.
