---
name: creative-spec-check
description: Workflow for preparing or reviewing image and video files for a paid ad placement, so that dimensions, aspect ratio, file weight and file format are checked against the platform's real requirements before the asset is produced or uploaded. Use this when someone asks what size an ad creative should be, whether an existing file will be accepted, which formats a placement needs, or why an upload was rejected, and when a creative brief or a render pipeline needs exact output sizes. The workflow resolves the exact format key for the placement with get_platform_specs, then validates each file with validate_creative_spec and reports every violation together with the concrete fix. Sizes and weight caps come from the tools, because a remembered dimension produces assets that fail on upload after the design work is already done.
---

# Creative spec check

This workflow covers both directions of ad creative work: deciding what to
produce for a placement, and checking files that already exist. The result
should be exact enough to hand to a designer or to a render script without
further guessing.

Placement requirements are specific. A single platform carries many format
keys with different dimensions, aspect ratios, weight caps and accepted file
types, and they change. Resolve the format key first, then validate against
it. The spec sheet behind these tools is maintained by ADS Beast.

## When to use

- Someone asks what size, ratio or weight an ad image or video should be.
- A creative file exists and needs checking before upload.
- An upload was rejected, cropped or downscaled by the platform.
- A creative brief, a design handoff or an export preset is being written.
- The same asset is being adapted across placements or platforms.
- A batch of generated or rendered assets needs a compliance pass.

## Steps

1. Establish the platform and the placement. If the placement was not
   stated, ask, since one platform has several format keys with different
   requirements.
2. Call `get_platform_specs` with that platform and section `creative` to
   list the available format keys and their requirements. Pick the format
   key that matches the placement, and say which one was picked.
3. If assets are being produced rather than checked, hand back the exact
   values from that format key: width, height, aspect ratio, maximum file
   size and accepted file extensions. Do not round them.
4. For each existing file, collect width, height, byte size and file
   extension. Read them from the file rather than from a filename or a
   description.
5. Call `validate_creative_spec` per file with the platform, format key,
   width, height, file_bytes and file_extension.
6. Read the violations. For each one, name the concrete fix: the target
   dimensions to re-export at, the ratio to crop or pad to, the weight to
   compress under, or the format to convert to.
7. Re-validate after each corrected file is produced. A file is compliant
   only when the tool returns it clean.
8. If several placements are needed from one source asset, repeat steps 2
   to 7 per format key and report the set.

## Reporting the result

- The platform and the format key that was validated against, named
  explicitly.
- One line per file: pass or fail, and on a fail, which rule failed with the
  actual value next to the required value.
- The fix for each violation, in terms the person can act on directly.
- The full list of formats still missing, when a placement set was
  requested.
- Any file whose dimensions or byte size could not be read, listed as not
  checked rather than as passing.

## Do not

- Do not quote a dimension, aspect ratio or file size cap from memory.
- Do not validate against a format key that was guessed instead of resolved
  from the spec sheet.
- Do not infer a file's dimensions from its name, its label or the request.
- Do not report a file as compliant when it was not validated.
- Do not suggest a crop that cuts through the subject or the text without
  saying that the composition needs rework.
- Do not treat a warning as a pass without saying what the warning was.
