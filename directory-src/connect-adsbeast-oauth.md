---
name: connect-adsbeast
description: How this plugin signs in to an ADS Beast workspace and what to do when a tool reports that access was refused. Use this when a tool returns 401 or 403, when someone asks how to connect, or when a tool that worked before starts refusing. Read what the connection carries with the whoami tool, compare it with what the failing tool needs, and say plainly what is missing. Access cannot be widened from the conversation.
---

# Connecting to ADS Beast

This plugin works with one ADS Beast workspace. The workspace, and what the
plugin may do in it, are decided when the connection is approved. Nothing in
a conversation can widen that.

## When to use

- A tool returned 401 or 403.
- Someone asks how to connect the plugin.
- A tool that used to work has started refusing.

## How the connection is made

1. On first use the assistant opens the ADS Beast sign-in page.
2. The person signs in to their ADS Beast workspace. A workspace owner or
   admin approves the connection on the consent screen. A manager can sign in
   but cannot approve; the screen says so and asks for an owner or admin.
3. The connection either reads only, or reads and proposes changes. Proposals
   wait for a person in ADS Beast unless the client opted in to automatic
   changes of that kind. A new campaign is always created paused.
4. Call `whoami`. It answers with the workspace, what the connection may do and
   the calls left this month.

The connection can be revoked at any time in ADS Beast under API Keys,
Connected assistants. After that every tool answers 401 until the person
connects again.

## When a tool refuses

- 401: the connection expired or was revoked. Ask the person to reconnect from
  the assistant's connector settings.
- 403 on a write: the connection was approved as read only. Say which action
  was refused and that an owner or admin can reconnect with proposals allowed.
- A plan limit: say which limit was reached and that the workspace owner can
  see the limits in ADS Beast. Do not suggest or promote a plan.

Never ask for a password, an API key or a one-time code in the chat.
