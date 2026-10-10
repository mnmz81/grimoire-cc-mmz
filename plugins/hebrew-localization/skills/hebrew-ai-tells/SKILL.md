---
name: hebrew-ai-tells
description: >
  Edit Hebrew text so it reads like a fluent Israeli wrote it. Strips the tells
  of machine-generated Hebrew — stock openers ("בעולם של היום"), filler
  ("חשוב לציין"), recap closers ("לסיכום"), eager-assistant phrases — and fixes
  gender-agreement slips, English word order, bureaucratic register, flat
  rhythm, stray nikud, and too much or too little English. Use when the user
  asks to make Hebrew sound natural or human ("שיישמע אנושי", "שלא יישמע כמו
  ChatGPT"), to review or polish AI-written Hebrew, or to tighten a Hebrew
  draft. Not for writing new copy from a brief (use hebrew-copywriting).
---

# Hebrew AI Tells

Machine-written Hebrew is usually grammatical enough and still unmistakable:
it is padded, over-formal, structured like English, and slips on gender. Your
job is to remove those signals while keeping the author's meaning, facts and
intended register.

## Ground rules

- Hebrew in, Hebrew out. Do not translate.
- Do not add claims, facts or examples that are not in the source.
- Keep the intended register. A legal notice stays formal; it just stops
  sounding generated.
- Keep English terms that people in the field really use. The goal is how
  Israelis write, not pure Hebrew.
- If the author's gender matters (first-person verbs and adjectives) and is
  unknown, ask before rewriting those forms.

## Pass 1 — Read and classify

Read the whole text before changing anything. Decide the context, because it
sets the target:

| Context | Target |
|---------|--------|
| News / article | Short sentences, active voice, named actors, facts first |
| Academic | Longer sentences and some formal connectors are fine; still no filler |
| Tech / dev | Direct, informal, English terms for technical concepts |
| Work messages (email, Slack) | Mid-register, first names, no ceremonial opening or closing |
| Social | Short, punchy, slang allowed |
| Children's material | The one place nikud belongs |

Then mark every problem from the layers below before you rewrite.

## Pass 2 — The layers, most visible first

### Layer A: Frames (always fix)

- **Stock openers** — `בעולם של היום`, `בעידן הדיגיטלי`, `בימינו`, `כיום יותר
  מתמיד`. Delete and start with the point.
- **Eager-assistant phrases** — `שאלה מצוינת!`, `בשמחה אעזור`, `בהחלט!`.
  Delete; open with the answer.
- **Recap closers** — `לסיכום`, `לאור כל האמור`, `כפי שראינו`. Delete if they
  only repeat; if a close is needed, end on a consequence or a next step.
- **Importance flags** — `חשוב לציין`, `יש לציין`, `ראוי להדגיש`, `כדאי לזכור`.
  Remove; if it matters, move it to the front of the sentence.

> `חשוב לציין שהגרסה עדיין בבטא ולכן ייתכנו תקלות.`
> → `הגרסה עדיין בבטא — יהיו תקלות.`

### Layer B: Grammar (always fix)

- **Gender agreement.** For every subject, find its grammatical gender and
  check every verb, adjective, participle and demonstrative tied to it — also
  across sentence boundaries. Feminine nouns are where generated text slips:
  `המערכת מאפשרת`, `התוצאות הראו`, `הגישה הזאת עובדת`.
- **Construct state.** No construct with proper names (`הלקוחות של נועה`,
  not `לקוחות נועה`); definite `ה־` on the last noun only; break chains longer
  than two links with `של` or a relative clause.
- **Verb–preposition pairs.** `מתייחס ל־`, `תלוי ב־`, `משפיע על`, `נוגע ל־`.
- **Definite article overuse.** Generic statements and predicates usually take
  none: `כלבים הם חיות נאמנות`, `היא מהנדסת`.
- **Nikud in modern prose.** Remove it, except children's material, poetry, or
  a single word that would otherwise be misread.

### Layer C: Structure

- **English word order.** Hebrew fronts what the sentence is about and ends on
  the new information. Let some sentences open with the object, a time phrase,
  or the verb: `את הבאג הזה מצאנו רק בפרודקשן.` / `נפל השרת באמצע הדמו.`
- **Nominalizations.** `ביצוע ניתוח של הנתונים` → `לנתח את הנתונים`; `קיום
  פגישה` → `להיפגש`.
- **Passive and impersonal hedging.** `נמצא כי`, `ניתן לראות`, `ניתן לטעון`
  → name who did it, or use first person or plural (`מצאנו`, `רואים ש`).
- **Enumeration on autopilot.** `ראשית… שנית… לבסוף`, `כמו כן… בנוסף` →
  real prose; keep lists only for steps, specs or genuinely parallel items.
- **Over-explaining.** Delete definitions of things the reader knows and
  `כלומר` clauses that repeat the previous sentence.

### Layer D: Rhythm

- **Even sentence length.** Mix one long sentence with two short ones. A
  three-word sentence after a long one lands the point.
- **Even paragraph length.** Let the key claim stand as a one-line paragraph.
- **Repetition.** The same noun phrase or evaluative adjective (`משמעותי`,
  `חשוב`, `ייחודי`, `מרשים`) three times in a short text → replace with a
  pronoun or, better, with a concrete detail.

### Layer E: Register and vocabulary

- **Bureaucratic words in everyday text** — `במסגרת`, `בהתאם לכך`, `על מנת`,
  `לאור זאת`, `התרחשות` → `ב־`, `אז`, `כדי`, `לכן`, `מה שקרה`.
- **Formal connectors piled up** — keep at most one per paragraph in
  non-academic text; often the logic works with none.
- **English density.** Too much (`לעשות קליק על הבאטן בפורם`) → use the Hebrew
  word people use (`ללחוץ על הכפתור בטופס`). Too little in tech text
  (`צינור האספקה`, `שלב הפריסה`) → `ה־pipeline`, `ה־deploy`.
- **Corporate loan-jargon outside startup context** — `אינסייט`, `סינרגיה`,
  `אקוסיסטם` → `תובנה`, `שיתוף פעולה`, `סביבה`.
- **Uniform, safe word choice.** One or two vivid, specific choices per text
  are enough. Do not decorate every sentence.

## Pass 3 — Rewrite, then re-read

Fix layers A and B everywhere. Apply C–E where they improve the text in its
context, not mechanically. Then re-read the result as an Israeli reader and
ask:

1. Is there any sentence that would make someone think "this is ChatGPT"?
2. Do all gender agreements hold, including across sentences?
3. Do sentence and paragraph lengths vary?
4. Does the register match the context from Pass 1?
5. Would a professional in this field use these terms, in this language mix?

If any answer is no, do another pass on that spot only.

## Output

Return the edited text, then a short note:

- The three changes that mattered most.
- Any judgment call (register kept, English terms kept on purpose, gender
  assumption) the author should confirm.

Keep the note brief — the text is the deliverable.
