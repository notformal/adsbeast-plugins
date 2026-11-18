---
name: account-audit
description: Workflow for auditing one client's advertising account through the ADS Beast workspace server. Use this when someone asks for an audit, a health check, a review of an account or client, or asks what is wrong with their ads. The workflow checks the connection with whoami, reads the client, its connected accounts and how fresh the data is, runs audit_campaign_portfolio and the platform audits (audit_google_ads, audit_meta_ads or audit_account), cross-checks alerts, rejected ads and pending proposals, then reports findings by severity with the evidence for each and a list of what could not be checked. A change is never a direct edit: it is prepared as a preview, shown to the person, and submitted with execute_prepared_change only after they confirm.
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
5. Call `client_data_freshness` with the `client_id`. If a platform was
   last synced long ago, every finding about it carries that date.
6. Call `audit_campaign_portfolio` with the `client_id`. It scores every
   campaign and names the ones in a critical state, without conversions,
   without goals or with stale data. This decides where to look deeper.
7. Run the platform audit that matches the connected accounts:
   `audit_google_ads` for Google, `audit_meta_ads` for Meta, `audit_account`
   with a `platform` for the others or for all at once. These take up to
   half a minute each. Do not run them twice because the first was slow.
8. Call `audit_ad_disapprovals` with the `client_id` for ads the platforms
   rejected, with the reason.
9. For single campaigns that stand out, call `campaign_analyze` or
   `get_campaign` for the detail. `list_campaigns` gives the plain list
   when it is needed; walk its pages while `has_more` is true.
10. Call `list_alerts` with the `client_id` and `is_resolved` false. An open
    critical alert is a finding by itself.
11. Call `list_proposals` with the `client_id`. A change that is already
    waiting for approval must not be prepared again.
12. Call `lead_pipeline_stats` with the `client_id` if the key has
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
  connected, an audit that was refused or returned nothing). The search
  terms report is not exposed by this server; do not imply it was reviewed.
- An audit score is the tool's own; quote it as such, with the problems
  behind it, and do not invent a score of your own.
- If the person wants a suggested change made: call
  `prepare_campaign_pause` or `prepare_campaign_budget_change` with the
  reason and the figures, show the preview, and on their yes call
  `execute_prepared_change`. Then say where it stands.

## Safety rules

These apply to every step above.

1. Check the connection first. Call `whoami` before anything else. If it
   fails, the key is missing, wrong or revoked: say so and stop. If it works,
   read the scopes it reports and do not call a tool whose scope is absent.
2. Amounts are in the currency of the ad account they came from. Never put a
   dollar sign on a figure because it is a number, never add up figures from
   accounts in different currencies, and name the currency next to every
   amount you report. If the currency is not in the data, say it is unknown.
   Budgets are whole units of that currency, never cents or micros.
3. Never retry a failed create. If `execute_prepared_change`,
   `create_campaign_draft`, `create_webhook` or a non-dry-run
   `push_lead_outcomes` returns an error or times out, do not send it again
   and do not prepare the same change a second time. Look first:
   `get_prepared_change` with the same `preview_id`, `list_proposals`,
   `list_campaign_drafts`, `list_webhooks`. Then report what you found. A
   repeated create is how duplicates and double changes happen.
4. Confirm before anything that affects spend. A change to an ad account
   takes two calls. A prepare tool stores a preview of exactly that change
   and returns a `preview_id` that works once, for 15 minutes. Show the
   person the preview (campaign, current value, new value, currency,
   reason) and wait for a clear yes in the conversation. Only then call
   `execute_prepared_change` with that id. Never prepare and execute in one
   breath.
5. Executing is not applying. After `execute_prepared_change` the change
   waits for a person to approve it in ADS Beast, unless the client's own
   write policy applies that kind of change automatically; the reply says
   which. This server cannot approve, and it cannot switch a campaign on
   without a person. If the preview's `write_control` lists `blocked_by`
   (emergency stop, observe-only mode and similar), say that the change can
   be queued but will not run until that is lifted. Report the real state
   from `get_prepared_change`, never "done" on your own word.
6. Empty is not healthy. An empty list can mean no access, no connected
   account or no synced data. Report it as "nothing returned" and name what
   was not checked. Do not turn a missing figure into zero.
7. A key bound to a single client is refused (403) by the audit and
   analytics tools. Pausing, enabling, a budget change and negative
   keywords still work with it. When that happens, fall back to
   `get_agency_kit`, `list_campaigns` and `get_campaign`, and say that the
   deeper analysis was not available to this key.
