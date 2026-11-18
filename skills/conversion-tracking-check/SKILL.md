---
name: conversion-tracking-check
description: Workflow for checking whether a client's conversion tracking is plausible, using the ADS Beast workspace server. Use this when someone asks if tracking works, why conversions are zero or dropped, whether leads are being counted, or before judging campaign performance. The workflow checks the connection with whoami, then compares three things the server holds: results the ad platforms report in get_agency_kit and list_campaigns, leads that actually arrived through get_new_leads with their attribution, and open tracking alerts. It reports where they disagree and what each disagreement suggests. It does not inspect tags on the website or settings inside the ad platform.
---

# Conversion-tracking check

Before anyone judges a campaign, check that its results are being counted.
A campaign with broken tracking looks exactly like a campaign that does not
work.

What this server can do is compare evidence it already holds. It cannot
open the website, fire a test event or read conversion settings inside the
ad platform. The result is a statement of what agrees, what does not and
what a person has to check by hand.

## When to use

- "Is tracking working", "why are conversions zero", "leads are not being
  counted".
- Conversions dropped suddenly with no change in spend or clicks.
- Before an audit, a wasted-spend hunt or any pause decision.

## Steps

1. Call `whoami`. Needs `read:clients`, `read:campaigns`, `read:leads`,
   `read:alerts`.
2. Call `get_client` with the `client_id`: which ad accounts are connected.
   A platform that is not connected reports nothing; that is not a tracking
   fault.
3. Call `get_agency_kit` for the conversions the platforms reported over
   the last 30 days, per account and campaign, and for the client's goals.
4. Call `list_campaigns` with the `client_id`. List campaigns that spend
   and report zero conversions.
5. Call `lead_pipeline_stats` with the `client_id` and `days` 30, and
   `get_new_leads` with `since` 30 days back. Look at the attribution on the
   leads: UTM values, click ids, platform form and campaign ids.
6. Call `list_lead_forms` with the `client_id` to see which forms feed
   leads in.
7. Call `list_alerts` with the `client_id` and `is_resolved` false, and
   read anything about tracking, conversions or measurement.
8. Compare:
   - platform reports conversions, no leads arrived: the conversion action
     may be counting the wrong event (page view, click), or leads are not
     reaching ADS Beast;
   - leads arrived, platform reports zero: the conversion is not being sent
     back to the platform, so it optimises blind;
   - leads arrive without click ids or UTM values: links are not tagged or
     the form drops the parameters, so results cannot be tied to campaigns;
   - conversions fell to zero on one date for every campaign of an account:
     something broke on that date (tag, consent banner, site release);
   - one platform's leads all come through instant forms while its
     campaigns point to the website: the website path is not measured.
9. If outcomes are never written back (no later-stage leads, the platform
   only knows "lead"), point to `lead_outcome_contract` and
   `push_lead_outcomes`: that is the loop that teaches the platform which
   leads became customers. Do not run a push as part of a check.

## Reading the result

Three states only: agrees, disagrees, not checked. Zero conversions on a
campaign with a few dozen clicks is not a fault. Unmeasured is not the same
as zero; say which one it is.

## Reporting the result

- Per platform: conversions reported, leads received, verdict.
- Each disagreement with its likely cause and the manual check that would
  confirm it (open the conversion action in the platform, submit a test
  lead, look at the tag on the thank-you page).
- What was not checked: tags, consent mode, conversion settings, offline
  imports. These are not visible from this server.
- No change is made by this workflow.

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
