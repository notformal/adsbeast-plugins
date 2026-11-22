# ADS Beast

Work with your own ADS Beast advertising workspace from Claude: audit ad
accounts, find wasted spend, check conversion tracking and budget pace,
compare platforms, review leads with their attribution, and prepare campaign
changes that a person approves.

## Connecting

The plugin connects to `https://adsbeast.pro/api/mcp/workspace` and signs in
with OAuth. On first use Claude opens the ADS Beast sign-in page; a workspace
owner or admin approves the connection on the consent screen. Nothing needs to
be copied or stored on your machine.

The connection belongs to one workspace. It can read only, or read and propose
changes. It can be revoked at any time in ADS Beast under API Keys, Connected
assistants.

## How changes work

A change takes two calls. The first stores a preview of exactly that change,
valid for 15 minutes and usable once. The second submits that preview and
nothing else. Unless the client opted in to automatic changes of that kind, a
person then approves it in ADS Beast. A new campaign is always created paused.

## Skills

Account audit, wasted-spend hunt, search terms and negatives, campaign launch,
budget pacing, weekly report, conversion tracking check, lead pipeline review,
creative fatigue check, cross-platform comparison, competitor ads review, and
a connection guide.

## Links

- Website: https://adsbeast.pro
- Support: https://adsbeast.pro/en/support, support@adsbeast.pro
- Privacy policy: https://adsbeast.pro/privacy
- Terms: https://adsbeast.pro/terms

Built and operated by Denha Nexus s.r.o., Bratislava, Slovakia.
