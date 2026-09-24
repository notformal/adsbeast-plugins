---
name: ad-copy-review
description: Workflow for writing or reviewing paid ad copy so that every headline, primary text, description and CTA is checked against the platform's current hard character limits before it is shown to the user. Use this when the request involves drafting, rewriting, shortening, translating or reviewing ad text for Google Ads, Meta, TikTok, LinkedIn or Microsoft Advertising, when someone asks whether a piece of copy will fit, or when an upload was rejected for length. The workflow gathers the platform and campaign type first, drafts, then validates with the validate_ad_copy and get_platform_specs tools, rewrites any field that overflows instead of truncating it, and reports the per-field character counts and what changed. Limits come from the tools, never from memory, because platform limits change and a misremembered limit produces copy the platform rejects on upload.
---

# Ad copy review

This workflow covers writing new paid ad copy and reviewing copy someone
else wrote. The point of it is that the text handed back is already known to
fit the platform's fields, so it can be pasted into the ad editor without a
length error.

Character limits differ per platform, per campaign type and per field, and
they change over time. Treat any limit recalled from memory as unverified.
The `get_platform_specs` and `validate_ad_copy` tools return the current
values from the Ad Spec Guard spec sheet, maintained by ADS Beast.

## When to use

- The request is to write, rewrite, shorten or translate ad copy for a paid
  campaign.
- The request is to review existing ad copy before it goes live.
- Someone asks whether a headline or description will fit.
- An ad was rejected or truncated on upload for being too long.
- Copy is being adapted from one platform to another, where the field
  structure and limits differ.

## Steps

1. Establish the platform. If it was not stated, ask. Copy cannot be
   validated without it.
2. Establish the campaign type or ad format where it matters, for example
   Search versus Performance Max, or feed versus Stories placement. Ask if
   it is ambiguous.
3. Call `get_platform_specs` with that platform, section `text`, before
   drafting. Use the returned field names and limits as the shape of the
   draft. Do not start from a remembered field list.
4. Write the draft to the field structure the specs returned. Keep each
   field within its limit while drafting rather than trimming afterwards.
5. Call `validate_ad_copy` with the platform, campaign type and the drafted
   fields. Read the per-field violations and their severity.
6. For every field marked `error`, rewrite that field so the message
   survives at the shorter length. Cut modifiers, split clauses, choose a
   shorter synonym. Do not cut the string at the limit and do not abbreviate
   into something unreadable.
7. Re-run `validate_ad_copy` on the rewritten set. Repeat until no `error`
   remains. Decide on each `warning` and say what was decided.
8. If policy risk is in scope for this request, run
   `check_ad_policy_preflight` on the final text before presenting it.

## Reporting the result

- The final copy, grouped by field, in the structure the platform expects.
- The character count and the limit for each field, from the tool output.
- Every field that was rewritten, with a one-line note on what was cut and
  why.
- Any remaining `warning` and the reason it was accepted.
- If the platform or campaign type was assumed rather than stated, say so
  and name the assumption.

## Do not

- Do not state or rely on a character limit from memory. Call the tool.
- Do not present copy that has not been through `validate_ad_copy`.
- Do not fix an overflow by truncating mid-word or appending an ellipsis.
  Rewrite the line.
- Do not silently drop a field that would not fit.
- Do not invent a field that the spec sheet did not return for that platform
  and campaign type.
- Do not report a character count that was counted by eye rather than
  returned by the tool.
