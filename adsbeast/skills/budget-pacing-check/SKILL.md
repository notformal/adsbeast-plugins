---
name: budget-pacing-check
description: Workflow for checking whether advertising budgets are on pace, using the ADS Beast workspace server. Use this when someone asks whether a client will overspend or underspend this month, how much budget is left, or which campaigns are running hot. The workflow checks the connection with whoami, reads the client budget and connected accounts, the campaign budgets and spend through list_campaigns and get_campaign, the 30-day results in get_agency_kit and open budget alerts, then reports pace per account in that account's currency. A budget change is only ever created as a proposal with propose_campaign_change after the person confirms the exact new amount.
---

# Budget pacing check

Answer one question per client: at the current rate, does the budget last
the period, run out early, or go unspent.

There is no dedicated pacing tool on this server. Pace is worked out from
the budget and spend figures the campaign and client tools return, so the
answer is only as fresh as the last sync, and it says so.

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
3. Call `get_agency_kit` for spend over the last 30 days per account and
   campaign.
4. Call `list_campaigns` with the `client_id`, all pages, and
   `get_campaign` where a row lacks budget or spend detail.
5. Work out pace per account, in that account's currency:
   - spent so far in the period against the budget for the period;
   - share of the period elapsed against share of the budget spent;
   - projected spend at the current daily rate.
   State the dates used. If the data does not say which period a spend
   figure covers, say that and do not project from it.
6. Call `list_alerts` with the `client_id` and `is_resolved` false. Budget,
   billing and delivery alerts change the reading: an account that stopped
   delivering is not "under pace", it is stopped.
7. Call `list_proposals` for the client. A budget change already waiting is
   part of the picture.
8. Report, then stop. Only if the person asks for a change: agree the
   campaign and the exact new amount, repeat it back with the currency, and
   on their yes call `propose_campaign_change` with `change_budget`,
   `new_budget` and a reason with the figures. `new_budget` is a monthly
   budget in the account currency.

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
- Proposal ids, if any were created, and that they wait for approval.

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
