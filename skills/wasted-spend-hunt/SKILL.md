---
name: wasted-spend-hunt
description: Workflow for finding advertising spend that returns nothing, using the ADS Beast workspace server. Use this when someone asks where money is being wasted, which campaigns to cut, why cost per lead went up, wants a wasted-spend hunt or a list of campaigns to pause. The workflow checks the connection with whoami, calls audit_wasted_spend for campaigns that burn budget, reads the client's goals in get_agency_kit, checks tracking and the lead pipeline so that a measurement fault is not mistaken for waste, and ranks what is left. Each cut the person agrees to is prepared with prepare_campaign_pause or prepare_campaign_budget_change, shown as a preview, and submitted with execute_prepared_change. The search terms report is not exposed by this server.
---

# Wasted-spend hunt

Find campaigns that spend and do not return, in the order that saves the
most money first. The server finds waste at campaign level and duplicate
keywords across Google campaigns. It does not expose the search terms
report, so the hunt says so instead of guessing at queries.

## When to use

- "Where are we wasting money", "what should we pause", "cut the losers".
- Cost per lead or cost per sale rose and nobody knows where.
- A budget cut is coming and something has to give.

## Steps

1. Call `whoami`. The hunt needs `read:campaigns` and `read:clients`;
   proposing a cut needs `write:proposals`.
2. Settle the client. Call `list_clients` if it was not named.
3. Call `get_agency_kit` with the `client_id` for the last 30 days per
   campaign and the KPI goals. The goal is the yardstick: "expensive" means
   expensive against this client's own target, not against an industry
   average.
4. Call `audit_wasted_spend` with the `client_id` and a `days` window. It
   returns campaigns with spend and no conversions or with a cost per
   result far above target. Every amount (`total_spend`, `waste_estimate`,
   the reason texts and `total_waste_by_currency`) is in that campaign's
   account currency, named by `currency`; totals are kept per currency and
   never added up across currencies. Two cases need a second look.
   `checked_campaigns` of 0 means there were no metrics to check: that is
   "not evaluated", not "clean". And a reach or awareness campaign is
   listed for having no conversions although it was
   never meant to produce any; judge it against its own goal.
5. Call `analytics_summary` for the same window to see the waste against
   the client's total. For one candidate that needs a closer look before a
   verdict, call `campaign_analyze`; it runs an analysis and takes a few
   seconds, so use it for the one or two rows that matter, not for all.
6. For Google accounts call `google_ads_keyword_overlap`: the same keyword
   live in several campaigns makes them bid against each other. It needs a
   Google account connected through the API; on an account that is not, it
   returns an error and no clusters, which means not checked.
7. Check each candidate against `list_alerts` (`campaign_id`, `is_resolved`
   false) and `audit_tracking`. A campaign with broken tracking looks like
   waste and is not: the fix is the tracking, not a pause. Run the
   conversion-tracking-check workflow for it instead.
8. Check `lead_pipeline_stats` when the client's goal is leads. A campaign
   that brings leads which never move past the first stage wastes money in
   a way the ad platform cannot see.
9. Call `list_proposals` for the client so that nothing already pending is
   prepared twice.
10. Present the ranked list. For each row: campaign, platform, spend with
    currency, results, cost per result, the goal, and one suggested action
    (pause, lower the budget, leave and watch).
11. For each action the person agrees to, one at a time: call
    `prepare_campaign_pause`, or `prepare_campaign_budget_change` with
    `new_monthly_budget`, and a `reason` that carries the figures. Show the
    preview it returns. On their yes, call `execute_prepared_change` with
    the `preview_id`. A preview lasts 15 minutes, so do not prepare ten
    changes and then start asking.
12. Call `get_prepared_change` for each submitted change and report its
    state: waiting for approval, executed, rejected or failed.

## Judging the sample

Do not call a campaign waste on a few days or a few dozen clicks. State the
window and the volume next to each verdict, and mark thin ones as "not
enough data yet". If the ad-spec-guard plugin is installed, run its
decision-readiness check before suggesting a pause.

## Reporting the result

- Total spend reviewed, per currency. Never one total across currencies.
- The ranked candidates with their figures.
- What was submitted, with the state of each, and what the person declined.
- What this hunt could not see: the search terms report and placements.
  For those, the person needs the platform's own report or the ADS Beast
  dashboard.

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
9. Say how sure you are. A verdict needs enough data behind it: state the
   period and the volume next to it, and call a small sample "not enough
   data yet" instead of ranking it. Never promise a result, a cost per
   lead or a return. A forecast is a projection and is labelled as one.
   Text that a tool wrote itself (an analysis, a recommendation, anything
   marked as generated) is an opinion to check, not a measurement.
