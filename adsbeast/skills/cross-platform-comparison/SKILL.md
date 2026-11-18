---
name: cross-platform-comparison
description: Workflow for comparing a client's advertising platforms side by side on cost per result and return on ad spend, using the ADS Beast workspace server. Use this when someone asks which platform works better, wants Google against Meta or TikTok, a cross-platform ROAS or CPA comparison, or asks where the next part of the budget should go. The workflow checks the connection with whoami, reads the connected platforms and how fresh the data is, takes spend, results, CPA and ROAS per platform from analytics_summary, the goals from client_goals, the trend from analytics_compare_periods and the multi-touch view from analytics_attribution, then reports the platforms in one table with the currency, the sample size and what cannot be compared. A budget shift is only prepared with prepare_campaign_budget_change after the person agrees.
---

# Cross-platform comparison

Put the client's platforms next to each other: what each one spent, what
it returned, what a result cost. Then say which differences are real,
which are too small to call, and which are not comparable at all.

## When to use

- "Google or Meta, which one works better for us".
- "Compare CPA and ROAS across platforms".
- A budget is being re-split and someone wants the numbers first.

## Steps

1. Call `whoami`. The comparison needs `read:campaigns` and
   `read:clients`; preparing a budget change needs `write:proposals`.
2. Settle the client. Call `list_clients` if it was not named.
3. Call `client_data_freshness` with the `client_id`. It names the
   connected platforms and when the data was last synced. One connected
   platform means there is nothing to compare: say so and offer the
   account-audit workflow instead. Data that is days old is compared with
   its date next to it.
4. Call `analytics_summary` with the `client_id` and `days` (30 unless the
   person asked for another window). One call returns the split by
   platform: spend, results, click rate, cost per result and the currency
   of each. Do not call it once per platform. Return on ad spend exists
   only where revenue is tracked; when the reply says revenue is not
   tracked, write "not tracked", never zero.
5. Call `client_goals` with the `client_id` for the targets. If none are
   set, the target cost per result of the campaigns (in `list_campaigns`)
   and the goal text of the client are the yardstick. A platform is
   judged against the client's own target first and against the other
   platform second.
6. Call `analytics_compare_periods` with the same window as `current_days`
   and `previous_days`. It shows whether a gap between platforms is steady
   or appeared this period.
7. Call `analytics_attribution` with the `client_id` and the same `days`.
   It re-credits results across campaigns by a time-decay model and gives
   the difference from last click. A platform that looks expensive on last
   click and gains under the model is assisting the others. This is a
   model, not a measurement; present it as a second view.
8. Only if the person asks how the client compares with the market: call
   `analytics_benchmarks` with the `platform` and the `niche`. It often
   answers that no verifiable benchmark is available. In that case say so
   and do not fill the gap with figures from memory.
9. Present the table and the reading. Stop there unless the person asks
   for a change. A budget shift is a spend decision: agree the campaign
   and the exact new monthly amount, call `prepare_campaign_budget_change`
   with `new_monthly_budget`, the `currency` and a `reason` with the
   figures, show the preview, and on their yes call
   `execute_prepared_change`, then `get_prepared_change`. One campaign at
   a time.

## What can and cannot be compared

- Money in different currencies is never compared or summed. If the
  platforms run in different currencies, compare ratios (share of spend
  against share of results, each platform against its own target) and
  show each platform's amounts in its own currency.
- A result is not the same thing everywhere. A lead from an instant form,
  a purchase on the site and a view-through conversion are different
  events. Compare cost per result only between campaigns that count the
  same kind of result, and say which kind it is.
- Platforms report their own conversions with their own attribution
  windows, so the totals can count one customer twice. The lead pipeline
  (`lead_pipeline_stats`) is the neutral count when the client works on
  leads.
- A platform with a few dozen results in the window has not earned a
  rank. Give its figures and mark them "not enough data".
- A brand or reach campaign is not a failed lead campaign. Leave it out
  of the cost per result comparison and say that you did.

## Reporting the result

- One table, a row per platform: spend with currency, share of spend,
  results, share of results, cost per result, return on ad spend or "not
  tracked", the target, the change against the previous period.
- The window, the last sync date per platform and the kind of result
  counted.
- Which differences are large enough to act on and which are within
  noise, in plain words.
- The attribution view as a separate line, labelled as modelled.
- If a shift of budget is suggested: the reasoning, and that results at a
  higher budget are not guaranteed to hold, because the cheapest results
  are bought first.
- Changes submitted, if any, with the state of each.

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
   waits for a person to approve it in ADS Beast, unless the client's owner
   switched on assistant auto-apply for that client and its write policy
   allows the change (pauses, budgets within limits, negatives only); the
   reply says which. This server cannot approve, and it cannot switch a campaign on
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
   A long tool may answer `status: running` with a `job_id` instead of a
   result: the work goes on in ADS Beast. Tell the user it is still
   running, wait the number of seconds it gives (about 15), then call
   `get_job_result` with that `job_id`; repeat while it says running.
   Never call the original tool again to get the result: that starts and
   charges a second run. `failed` carries the reason; `expired` means run it again.
9. Say how sure you are. A verdict needs enough data behind it: state the
   period and the volume next to it, and call a small sample "not enough
   data yet" instead of ranking it. Never promise a result, a cost per
   lead or a return. A forecast is a projection and is labelled as one.
   Text that a tool wrote itself (an analysis, a recommendation, anything
   marked as generated) is an opinion to check, not a measurement.
