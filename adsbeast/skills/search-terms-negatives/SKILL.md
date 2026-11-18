---
name: search-terms-negatives
description: Workflow for turning a search terms report into negative keywords for a Google or Microsoft search campaign managed in ADS Beast. Use this when someone shares or pastes a search terms export, asks which queries to exclude, wants a negative keyword sweep, or wants negatives added to a campaign that is being drafted. The workspace server does not expose a search terms report, so the terms come from the person's own export. The workflow checks the connection with whoami, classifies the terms, has the person confirm the list, and then prepares a shared negative keyword list for the Google Ads account with prepare_negative_keywords_add, shows the preview and submits it with execute_prepared_change. For a campaign still in the builder the negatives go into the draft with update_campaign_draft.
---

# Search terms and negatives

Decide which search queries a campaign should stop paying for, and put the
confirmed list where a person can publish it.

Read this first: the workspace server has no tool that returns search
terms. Two things follow.

- The search terms come from the person: an export from the ad platform, or
  rows pasted into the conversation. If they have none, tell them where to
  export it and stop. Do not invent queries.
- Negatives can be written in two places. For a Google Ads account,
  `prepare_negative_keywords_add` prepares a shared negative keyword list
  for the client. For a campaign that is still a draft, they go into
  `negative_keywords` on `create_campaign_draft` or `update_campaign_draft`.
  For a live Microsoft campaign there is no write path here: the result is
  a reviewed list for a person to apply.

## When to use

- A search terms export was shared and someone asks what to exclude.
- A search campaign is being drafted and needs negatives from day one.
- Cost per result rose on a search campaign and irrelevant queries are
  suspected.

## Steps

1. Call `whoami`. Reading needs `read:campaigns`; preparing negatives or
   writing a draft needs `write:proposals`.
2. Identify the campaign. Use `list_campaigns` with the `client_id` and the
   platform, then `get_campaign`, so the list is judged against what the
   campaign actually sells. Call `get_agency_kit` for the client's offer,
   geography and goals.
3. Get the search terms from the person, with cost and conversions per
   term and the date range. Ask for the range if it is missing.
4. Classify every term:
   - irrelevant intent (jobs, free, how-to, a different product, a
     competitor the client does not want): negative candidate;
   - relevant but no result yet: keep, and say the sample is small;
   - relevant and converting: keep, and suggest it as a keyword.
5. For each candidate choose the narrowest negative that removes it: an
   exact or phrase negative for one bad query, a single word only when that
   word is wrong in every context. Check each proposed negative against the
   converting terms; a negative that would block a converting query is
   dropped.
6. Show the person the list: negative, match type, the queries it removes,
   what they cost in the account currency. Wait for confirmation. They may
   strike rows.
7. For a live Google Ads account: call `prepare_negative_keywords_add`
   with the `client_id`, the confirmed `keywords`, a `list_name` and the
   `reason`. Show the preview it returns. A shared list applies across the
   account's campaigns, so say that before the person agrees; a negative
   that suits one campaign may hurt another. On their yes, call
   `execute_prepared_change` with the `preview_id`, then
   `get_prepared_change` to report where it stands.
8. If the campaign is a draft in the builder (`list_campaign_drafts`,
   `get_campaign_draft`), write the confirmed list with
   `update_campaign_draft`. `negative_keywords` replaces the stored list
   whole, so send the existing negatives plus the new ones.
9. For a live campaign on another platform, hand over the confirmed list
   for a person to apply, and say that this server did not change the
   campaign.

## Reporting the result

- Date range and number of terms reviewed.
- Confirmed negatives with match type, and the spend they covered, with
  currency.
- Converting terms worth adding as keywords.
- Where the list went: submitted as a shared list and its current state,
  written to draft id N, or handed over for manual application. "Negatives
  added" is true only when `get_prepared_change` says executed.

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
