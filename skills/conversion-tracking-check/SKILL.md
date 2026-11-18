---
name: conversion-tracking-check
description: Workflow for checking whether a client's conversion tracking is plausible, using the ADS Beast workspace server. Use this when someone asks if tracking works, why conversions are zero or dropped, whether leads are being counted, or before judging campaign performance. The workflow checks the connection with whoami, runs audit_tracking for pixel, GA4 and tag mismatches and audit_conversion_goals for what the campaigns optimise on, then compares what the platforms report with the leads that actually arrived through get_new_leads and their attribution. It reports what agrees, what does not and what each disagreement suggests. Creating a missing conversion action is a prepared change that the person confirms.
---

# Conversion-tracking check

Before anyone judges a campaign, check that its results are being counted.
A campaign with broken tracking looks exactly like a campaign that does not
work.

The server runs its own tracking diagnostics and can compare them with the
leads it holds. It cannot fire a test event or submit a test lead. The
result is a statement of what agrees, what does not and what a person has
to check by hand.

## When to use

- "Is tracking working", "why are conversions zero", "leads are not being
  counted".
- Conversions dropped suddenly with no change in spend or clicks.
- Before an audit, a wasted-spend hunt or any pause decision.

## Steps

1. Call `whoami`. Needs `read:clients`, `read:campaigns`, `read:leads`,
   `read:alerts`; `write:proposals` only if something will be created.
2. Call `get_client` with the `client_id`: which ad accounts are connected.
   A platform that is not connected reports nothing; that is not a tracking
   fault.
3. Call `audit_tracking` with the `client_id`: pixel, GA4 and tag
   mismatches on the landing page, conversion actions and the other
   tracking guards, in one report.
4. Call `audit_conversion_goals` with the `client_id`: which conversions
   are primary, whether calls and forms are counted, and campaigns that
   optimise for the wrong goal. For one named conversion in Google Ads,
   `google_ads_conversion_tracking_check` with the `client_id` and its
   `name` says which existing action fits or what would have to be created.
   Then `get_agency_kit` for the conversions reported over the last 30
   days and `list_campaigns` for campaigns that spend and report none.
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
10. If a Google conversion action is missing and the person wants it
    created: `prepare_google_conversion_action_create` with the
    `client_id`, a `name` and a `reason`, show the preview, and on their
    yes `execute_prepared_change`. The result carries tag code that
    someone still has to put on the site; say so.

## Reading the result

Three states only: agrees, disagrees, not checked. Zero conversions on a
campaign with a few dozen clicks is not a fault. Unmeasured is not the same
as zero; say which one it is.

## Reporting the result

- Per platform: conversions reported, leads received, verdict.
- Each disagreement with its likely cause and the manual check that would
  confirm it (open the conversion action in the platform, submit a test
  lead, look at the tag on the thank-you page).
- What was not checked: a live test event, consent mode behaviour, offline
  imports. Say which of the audits ran and which were refused or empty.
- Any change submitted, with its state from `get_prepared_change`.
  Otherwise: no change was made.

## Safety rules

These apply to every step above.

1. Check the connection first. Call `whoami` before anything else. If it
   fails, the key is missing, wrong or revoked: say so and stop. If it works,
   read the scopes it reports and do not call a tool whose scope is absent.
2. Amounts are in the currency of the ad account they came from. Never put a
   dollar sign on a figure because it is a number, never add up figures from
   accounts in different currencies, and name the currency next to every
   amount you report. If the currency is not in the data, say it is unknown.
   Budgets are whole units of that currency, never cents or micros.
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
   waits for a person to approve it in ADS Beast, unless the client's own
   write policy applies that kind of change automatically; the reply says
   which. This server cannot approve, and it cannot switch a campaign on
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
