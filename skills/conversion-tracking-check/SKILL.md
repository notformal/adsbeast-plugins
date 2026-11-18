---
name: conversion-tracking-check
description: Workflow for checking whether a client's conversion tracking is plausible, using the ADS Beast workspace server. Use this when someone asks if tracking works, why conversions are zero or dropped, whether leads are being counted, wants a tracking watchdog check, or before judging campaign performance. The workflow checks the connection with whoami, runs audit_tracking for pixel, GA4 and tag mismatches and audit_conversion_goals for what the campaigns optimise on, then compares what the platforms report with the leads that actually arrived through get_new_leads and their attribution. It reports what agrees, what does not and what each disagreement suggests. Creating a missing conversion action is a prepared change that the person confirms.
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
2. Call `get_agency_kit` with the `client_id`: which ad accounts are
   connected and how, and the conversions each campaign reported over the
   last 30 days. A platform that is not connected reports nothing; that is
   not a tracking fault.
3. Call `audit_tracking` with the `client_id`: pixel, GA4 and tag
   mismatches on the landing page, conversion actions and the other
   tracking guards, in one report.
4. Call `audit_conversion_goals` with the `client_id`: which conversions
   are primary, whether calls and forms are counted, and campaigns that
   optimise for the wrong goal. For one named conversion in Google Ads,
   `google_ads_conversion_tracking_check` with the `client_id` and its
   `name` says which existing action fits or what would have to be created.
   Both need a Google account connected through the API. Without one the
   first says there is nothing to check and the second answers with an
   error: report that as not checked and do not call it again.
   The kit from step 2 already lists the campaigns that spend and report
   no conversions; do not fetch it again.
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
    someone still has to put on the site; say so. The prepare call
    rehearses the change first and stores no preview when the rehearsal
    fails; relay what it names instead of trying again.

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
