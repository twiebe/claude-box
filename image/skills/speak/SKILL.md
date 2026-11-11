---
name: speak
description: Turn spoken output through `say` on or off for this session (off | sparse | chatty). Use when the user runs /speak or explicitly asks Claude to say something out loud.
argument-hint: "[off|sparse|chatty]"
---

# Speaking to the user

In a claude box started with `cb --speak`, `say` speaks on the user's host,
through whatever speech command the host has set up.

```sh
say "One short sentence."
echo "One short sentence." | say
```

`say` returns at once; the host speaks afterwards. Exit 0 means delivered, not
heard - only the user knows whether it came through.

The user can quiet every box from the host with `cb speech off` or
`cb speech pause 30m`, in a meeting say. `say` cannot tell: it still exits 0
and the text is dropped. Do not retry, and do not repeat it later - whatever
was said is in the terminal anyway.

## Setting the mode

The default is **off**: without this command a session never speaks on its
own. The mode chosen holds until the session ends or the next `/speak`.

Argument: `$ARGUMENTS`

- empty, `sparse`, `sparsam` -> **sparse**
- `chatty`, `gesprächig`, `gespraechig` -> **chatty**
- `off`, `stop`, `aus` -> **off**
- anything else: ask which mode was meant

Before turning it on, check that this box can speak:

```sh
[ -n "$CB_SPEAK_SOCKET$CB_SPEAK_ADDR" ] && command -v say
```

If that fails, do not turn it on. Tell the user the box has to be restarted
with `cb --speak` (or `cb --continue --speak` to keep the conversation).

Otherwise confirm the mode with one short `say`, e.g. "Huhu, ich bin's. Sprache an, sparsam."
When turning it off, confirm in text only.

## The modes

**sparse** - speak only when
- a task that ran for more than a minute or two is done,
- you are waiting for the user: a question, an approval, a decision,
- something went wrong that the user needs to know about,
- the user asks for it.

**chatty** - as sparse, plus a short status at each larger step of long work
(not at every tool call).

**off** - speak only when the user explicitly asks for it.

## How to speak

- In German by default, whatever language the user writes in: the host's
  voice is usually German (Thorsten), and English through it sounds wrong.
  Speak another language only when the user asks for it.
- Open every `say` with a short call for attention, its own sentence, then the
  message. Said straight away, the first words go by before anyone listens.
  Vary the opener, a little wink is welcome, for example:
  - "Hallo, ich wieder."
  - "Huhu, ich bin's wieder."
  - "So, da bin ich wieder."
  - "Hallo, ich hab hier was für dich."
  - "Kurze Durchsage."
  - "Psst, kurz mal herhören."
  - "Klopf, klopf."
  - "Tadaa."
  - "Hach, du schon wieder? Ach nein, ich."
  - "Entschuldige die Störung."
  Pick one that fits: something cheerful for good news, something gentler for
  a problem or a question. Not the same one twice in a row.
- One or two short sentences after that. Everything said is in the terminal
  anyway - the voice is the nudge, not the report.
- Nothing that sounds bad read aloud: no code, paths, hashes, URLs, tables or
  lists. "Die Tests laufen durch" rather than "358 tests OK in 0.19s".
- No secrets, tokens or passwords - the room is listening.
- One `say` per occasion, not several in a row.
