---
name: weekly-report
description: Workflow for preparing a weekly advertising summary for one client from the ADS Beast workspace server. Use this when someone asks for a weekly report, a status update for a client, a summary of what happened this week, or what to tell the client. The workflow checks the connection with whoami, reads the week's figures with analytics_summary and the change against the week before with analytics_compare_periods, then alerts, proposals, tasks and the lead pipeline, and writes a short factual summary with amounts in the account currency. It reports only figures the tools returned and names the period each one covers. With the person's agreement it saves the text in ADS Beast with report_create. It does not email anything to the client.
---

# Weekly report

A one-page status for one client: results, what changed, what is waiting,
what happens next. Written from what the server returns, with no figure
that cannot be traced to a tool reply.

The output is text in the conversation for a person to review. It can be
saved to the client's reports in ADS Beast. Sending it to the client stays
with the person.

## When to use

- "Weekly report for", "what happened this week", "status for the client".
- Preparing for a client call.

## Steps

1. Call `whoami`. Useful scopes: `read:clients`, `read:campaigns`,
   `read:reports`, `read:alerts`, `read:leads`, `read:tasks`,
   `read:proposals`. Write the report from what the key can reach and list
   the sections that were skipped.
2. Call `list_reports` with the `client_id`. If a recent report covers the
   week, build on it and say which report and period it is.
3. Call `analytics_summary` with the `client_id` and `days` 7 for the
   week's spend and results, and `analytics_compare_periods` with
   `current_days` 7 and `previous_days` 7 for what moved. Call
   `get_agency_kit` for the goals. Its results cover 30 days: do not
   present a 30-day figure as the week.
4. Call `list_campaigns` with the `client_id` for what is running, paused
   and new.
5. Call `list_alerts` with the `client_id`: what fired this week and what is
   still open.
6. Call `list_proposals` with the `client_id`, once for pending and once
   with `status` set to executed, for changes waiting and changes made.
7. Call `lead_pipeline_stats` with the `client_id` and `days` 7 for leads by
   stage. If the client works on leads, `get_new_leads` with `since` set to
   the start of the week gives the new ones; report counts and sources, not
   names or phone numbers.
8. Call `list_tasks` with the `client_id` for work done and work open.
9. Write the summary and show it.
10. If the person wants it kept, call `report_create` with the `client_id`,
    a `title` and the text as `content`. Always pass `content`: without it
    the tool generates its own 30-day summary instead of saving yours. It
    needs `write:proposals`. Call it once.

## Shape of the report

- Headline: one sentence on the week against the goal.
- Results: spend, results, cost per result, per account, each with its
  currency and its period. No cross-currency total.
- What changed: launches, pauses, budget changes, with dates.
- Problems: open alerts in plain words, and what is being done.
- Waiting for a decision: pending proposals.
- Next week: the open tasks that matter.

## Writing rules

- Every figure comes from a tool reply. No estimates presented as results,
  no industry averages, no forecast unless the person asks and it is
  labelled as one.
- No personal data of leads in a client-facing summary.
- Plain sentences. No filler, no praise of the numbers. If the week was
  bad, the first line says so.
- A missing figure is written as "not available", never as zero.

## Reporting the result

The summary itself, followed by a short note to the person: which period
each block covers, which sections were skipped and why, whether it was
saved in ADS Beast, and that nothing was sent to the client.

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
