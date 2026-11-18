---
name: weekly-report
description: Workflow for preparing a weekly advertising summary for one client from the ADS Beast workspace server. Use this when someone asks for a weekly report, a status update for a client, a summary of what happened this week, or what to tell the client. The workflow checks the connection with whoami, reads reports already generated in ADS Beast with list_reports, the client's results in get_agency_kit, campaigns, alerts, proposals, tasks and the lead pipeline, and writes a short factual summary with amounts in the account currency. It reports only figures the tools returned and names the period each one covers. It does not generate or send a report document.
---

# Weekly report

A one-page status for one client: results, what changed, what is waiting,
what happens next. Written from what the server returns, with no figure
that cannot be traced to a tool reply.

This server reads reports that ADS Beast already generated; it has no tool
that creates or sends one. The output of this workflow is text in the
conversation for a person to review and send.

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
3. Call `get_agency_kit` with the `client_id` for goals and the last 30
   days of results. This is a 30-day window, not a 7-day one. Do not present
   30-day figures as the week. If no tool returned a 7-day figure, the
   report says "last 30 days" where it uses them.
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
9. Write the summary.

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
each block covers, which sections were skipped and why, and that nothing
was sent to the client.

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
