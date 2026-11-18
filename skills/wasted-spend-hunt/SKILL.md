---
name: wasted-spend-hunt
description: Workflow for finding advertising spend that returns nothing, using the ADS Beast workspace server. Use this when someone asks where money is being wasted, which campaigns to cut, why cost per lead went up, or wants a list of campaigns to pause. The workflow checks the connection with whoami, pulls campaigns with spend and results through list_campaigns, get_campaign and get_agency_kit, cross-checks open alerts and the lead pipeline, ranks candidates by spend without result, and for each cut the person confirms creates a proposal with propose_campaign_change. It works at campaign level: keyword and search-term data is not exposed by this server.
---

# Wasted-spend hunt

Find campaigns that spend and do not return, in the order that saves the
most money first. This server shows campaign-level figures. It does not
expose keyword, search-term or placement rows, so the hunt ends at the
campaign and says so.

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
4. Call `list_campaigns` with the `client_id`, all pages. Keep the active
   ones.
5. Rank candidates:
   - spend above zero and no conversions in the window;
   - cost per result more than twice the goal;
   - spend rising while results fall.
   Use `get_campaign` when the list row does not carry enough to judge.
6. Check each candidate against `list_alerts` (`campaign_id`, `is_resolved`
   false). A campaign with broken tracking looks like waste and is not: the
   fix is the tracking, not a pause. Run the conversion-tracking-check
   workflow for it instead.
7. Check `lead_pipeline_stats` when the client's goal is leads. A campaign
   that brings leads which never move past the first stage wastes money in
   a way the ad platform cannot see.
8. Call `list_proposals` for the client so that nothing already pending is
   proposed twice.
9. Present the ranked list. For each row: campaign, platform, spend with
   currency, results, cost per result, the goal, and one suggested action
   (pause, lower the budget, leave and watch).
10. For every action the person approves in the conversation, call
    `propose_campaign_change` once: `pause_campaign`, or `change_budget`
    with `new_budget`, and a `reason` that carries the figures. Report the
    proposal id and that it waits for approval in ADS Beast.

## Judging the sample

Do not call a campaign waste on a few days or a few dozen clicks. State the
window and the volume next to each verdict, and mark thin ones as "not
enough data yet". If the ad-spec-guard plugin is installed, run its
decision-readiness check before suggesting a pause.

## Reporting the result

- Total spend reviewed, per currency. Never one total across currencies.
- The ranked candidates with their figures.
- What was proposed (ids) and what the person declined.
- What this hunt could not see: search terms, keywords, placements,
  creatives. For those, the person needs the platform's own report or the
  ADS Beast dashboard.

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
