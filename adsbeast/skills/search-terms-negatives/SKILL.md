---
name: search-terms-negatives
description: Workflow for turning a search terms report into negative keywords for a Google or Microsoft search campaign managed in ADS Beast. Use this when someone shares or pastes a search terms export, asks which queries to exclude, or wants negatives added to a campaign that is being drafted. The workspace server does not expose a search terms report, so the terms come from the person's own export. The workflow checks the connection with whoami, classifies the terms, has the person confirm the list, and writes the confirmed negatives into a campaign draft with create_campaign_draft or update_campaign_draft, where a person reviews and publishes them.
---

# Search terms and negatives

Decide which search queries a campaign should stop paying for, and put the
confirmed list where a person can publish it.

Read this first: the workspace server has no tool that returns search
terms, and no tool that adds a negative keyword to a live campaign. Two
things follow.

- The search terms come from the person: an export from the ad platform, or
  rows pasted into the conversation. If they have none, tell them where to
  export it and stop. Do not invent queries.
- Negatives can be written from here only into a campaign draft
  (`negative_keywords` on `create_campaign_draft` and
  `update_campaign_draft`). For a campaign that is already live, the result
  of this workflow is a reviewed list for a person to apply.

## When to use

- A search terms export was shared and someone asks what to exclude.
- A search campaign is being drafted and needs negatives from day one.
- Cost per result rose on a search campaign and irrelevant queries are
  suspected.

## Steps

1. Call `whoami`. Reading needs `read:campaigns`; writing a draft needs
   `write:proposals`.
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
7. If the campaign is a draft in the builder (`list_campaign_drafts`,
   `get_campaign_draft`), write the confirmed list with
   `update_campaign_draft`. `negative_keywords` replaces the stored list
   whole, so send the existing negatives plus the new ones.
8. If the campaign is live, hand over the confirmed list for a person to
   apply in ADS Beast or in the ad platform, and say that this server did
   not change the campaign.

## Reporting the result

- Date range and number of terms reviewed.
- Confirmed negatives with match type, and the spend they covered, with
  currency.
- Converting terms worth adding as keywords.
- Where the list went: written to draft id N, or handed over for manual
  application. Never "negatives added" for a live campaign.

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
