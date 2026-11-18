---
name: budget-pacing-check
description: Workflow for checking whether advertising budgets are on pace, using the ADS Beast workspace server. Use this when someone asks whether a client will overspend or underspend this month, how much budget is left, which campaigns are running hot, or wants a budget watchdog check. The workflow checks the connection with whoami, reads the client budget and connected accounts, how fresh the data is, spend through analytics_summary and the campaign tools, the trend in analytics_forecast and open budget alerts, then reports pace per account in that account's currency. A budget change is prepared with prepare_campaign_budget_change, shown as a preview with the exact amount, and submitted with execute_prepared_change only after the person confirms.
---

# Budget pacing check

Answer one question per client: at the current rate, does the budget last
the period, run out early, or go unspent.

There is no dedicated pacing tool on this server. Pace is worked out from
the budget and spend figures the client, campaign and analytics tools
return, so the answer is only as fresh as the last sync, and it says so.

## When to use

- "Are we on pace", "will we overspend", "how much is left this month".
- Mid-month check before moving money between campaigns.
- An alert about budget or delivery came in.

## Steps

1. Call `whoami`. Needs `read:clients` and `read:campaigns`; `read:alerts`
   for the alert cross-check; `write:proposals` only if a change will be
   proposed.
2. Call `get_client` for the client's budget, its period and the connected
   accounts with their currencies.
3. Call `client_data_freshness` with the `client_id`. Pace computed from
   data that is days old is reported with that date, or not at all.
4. Call `analytics_summary` with the `client_id` and `days` set to the days
   elapsed in the period. One call already splits the figures by platform
   and by currency; pass a `platform` only to narrow it. Use
   `list_campaigns` and `get_campaign` for the budget of each campaign.
5. Work out pace per account, in that account's currency:
   - spent so far in the period against the budget for the period;
   - share of the period elapsed against share of the budget spent;
   - projected spend at the current daily rate.
   State the dates used. If the data does not say which period a spend
   figure covers, say that and do not project from it.
6. Call `analytics_forecast` and `analytics_forecast_warnings` with the
   `client_id`. They extrapolate the recent trend. Present them as a
   projection, labelled as one, next to your own arithmetic; where the two
   disagree, show both.
7. Call `list_alerts` with the `client_id` and `is_resolved` false. Budget,
   billing and delivery alerts change the reading: an account that stopped
   delivering is not "under pace", it is stopped.
8. Call `list_proposals` for the client. A budget change already waiting is
   part of the picture.
9. Report, then stop. Only if the person asks for a change: agree the
   campaign and the exact new amount, then call
   `prepare_campaign_budget_change` with `new_monthly_budget` and a reason
   with the figures. `new_monthly_budget` is per month, in whole units of
   the account currency. The preview shows the daily amount and the exact
   figure the platform will receive: read both back to the person. On
   their yes call `execute_prepared_change` with the `preview_id`, then
   `get_prepared_change` for the state.

## Reading the result

- Ahead of pace with good results is a decision for the person, not an
  error to correct.
- Behind pace is often a delivery problem (disapproved ads, billing, narrow
  targeting), and raising the budget does not fix those.
- Accounts in different currencies are reported side by side, never summed.

## Reporting the result

- Per account: budget, spent, projected, currency, period, verdict.
- Campaigns that drive the deviation.
- Alerts and pending proposals that affect the reading.
- How fresh the figures are, if the data says; otherwise that freshness is
  unknown.
- Changes submitted, if any, and the state of each.

## Safety rules

These apply to every step above.

1. Check the connection first. Call `whoami` before anything else. If it
   fails, the key is missing, wrong or revoked: say so and stop. If it works,
   read the scopes it reports and do not call a tool whose scope is absent.
2. Amounts are in the currency of the ad account they came from. Never put a
   dollar sign on a figure because it is a number, never add up figures from
   accounts in different currencies, and name the currency next to every
   amount you report. If the currency is not in the data, say it is unknown.
   Budgets are whole units of that currency, never cents or micros. Some
   tool texts print a dollar sign in front of an amount; go by the currency
   field of the reply and of the account, not by the sign. Only fields
   whose name ends in usd are US dollars.
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
8. Spend calls sparingly. Every tool call except `whoami` counts against
   the monthly allowance of the plan, and `whoami` shows how many are
   left. Reuse a reply you already have, pass the `client_id` instead of
   reading everything, and stop paging when the question is answered.
   Tools that run an analysis on the ADS Beast side (their description
   says so: an audit, a campaign analysis, a strategy, competitor
   research) are slower, and a plan may meter them separately as assistant
   questions. Run one only when the plain figures do not answer the
   question, never twice for the same question. If a tool reports that an
   allowance is used up, pass on the reset date it gives and carry on with
   what is still available.
9. Say how sure you are. A verdict needs enough data behind it: state the
   period and the volume next to it, and call a small sample "not enough
   data yet" instead of ranking it. Never promise a result, a cost per
   lead or a return. A forecast is a projection and is labelled as one.
   Text that a tool wrote itself (an analysis, a recommendation, anything
   marked as generated) is an opinion to check, not a measurement.
