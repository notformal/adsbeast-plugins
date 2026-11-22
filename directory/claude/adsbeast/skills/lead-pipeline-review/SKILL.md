---
name: lead-pipeline-review
description: Workflow for reviewing a client's lead pipeline in ADS Beast and feeding outcomes back, using the workspace server. Use this when someone asks about new leads, lead quality, which leads are stuck, which sources bring customers, or wants to record which leads were won or lost. The workflow checks the connection with whoami, reads stage counts with lead_pipeline_stats and leads with their attribution through get_new_leads, groups them by source and stage, and for outcome updates uses push_lead_outcomes as a dry run first, then applies it once after the person confirms. Contact details are used to work the leads and are kept out of summaries.
---

# Lead pipeline review

Look at leads the way a sales lead would: how many came in, from where,
where they are stuck, which sources turn into customers. Then, if the
person has outcomes, write them back so the ad platforms stop optimising
for volume.

## When to use

- "Show me new leads", "how is lead quality", "which leads are stuck".
- "Which campaigns bring customers, not just leads."
- A list of won and lost deals has to be recorded.

## Steps: review

1. Call `whoami`. Reading needs `read:leads`; changing a lead or pushing
   outcomes needs `write:leads`.
2. Call `lead_pipeline_stats` with the `client_id` and a `days` window that
   matches the question. This is the overview: counts per stage.
3. Call `get_new_leads` with `since` or `updated_since` and the `client_id`.
   Walk the pages with `next_offset` while `has_more` is true.
4. Call `list_lead_forms` so that form ids on the leads become readable
   names.
5. Group the leads by source and campaign (from the attribution), then by
   stage. Flag:
   - leads still in the first stage after several days;
   - sources with many leads and none past the first stage;
   - leads with no attribution at all.
6. For one lead in detail use `get_lead`.

## Steps: changes to single leads

7. To move a lead, use `move_lead_stage`; it also resets the close
   probability for the new stage. To change notes, assignee or contact
   fields, use `update_lead` with only the keys that change. Say what will
   change and get a yes first when the person did not ask for that exact
   edit.

## Steps: writing outcomes back

8. Call `lead_outcome_contract` to see the outcome values and fields the
   server accepts right now. Do not guess them.
9. Build the rows from what the person gave. Amounts carry their own
   currency code in the row.
10. Call `push_lead_outcomes` with `dry_run` true. Read the reply: which
    rows matched a lead, which did not, what would change.
11. Show that to the person. Unmatched rows are usually a typo in an email
    or phone; fix them with the person. Leave `create_missing` false unless
    they explicitly want new leads created from unmatched rows.
12. On their confirmation call `push_lead_outcomes` once with `dry_run`
    false. This is the step that affects optimisation on the ad platforms,
    which in turn affects where money goes. If it errors or times out, do
    not send it again: check a few of the leads with `get_lead` to see
    whether the batch was applied, and report.

## Privacy

Leads are people. Names, emails and phone numbers are shown when the
person is working a specific lead, and left out of summaries, comparisons
and anything meant for a client or a wider audience. Never paste lead
contact data into another tool or service.

## Reporting the result

- Counts per stage and per source for the window.
- Stuck leads and silent sources.
- For an outcome push: rows sent, matched, applied, skipped, with the
  reason for each skip.
- What was not looked at.

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
