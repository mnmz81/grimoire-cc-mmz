---
name: hebrew-copywriting
description: >
  Write or edit Hebrew copy for products and marketing — UI microcopy, error
  messages, buttons, empty states, emails, landing pages, articles and social
  posts. Use when the user asks to write or phrase something in Hebrew
  ("תכתוב בעברית", "נסח לי", "תקן את העברית"), adapt English copy to Hebrew,
  pick a tone (formal, business, direct, casual), address the reader without
  guessing their gender, mix English tech terms into Hebrew, or format
  numbers, dates and Hebrew punctuation inside copy. Not for de-AI-ing a
  finished draft (use hebrew-ai-tells) or i18n code (use hebrew-i18n).
---

# Hebrew Copywriting

Write Hebrew the way a sharp Israeli product writer would: short, direct,
grammatically clean, and native — never English with Hebrew words.

## Workflow

1. **Pin the brief.** Surface (UI string, email, article, post), audience, and
   voice. If the voice is not given and cannot be inferred, ask once.
   Otherwise default: UI → direct; marketing → business-casual; legal or
   official → formal.
2. **Draft in Hebrew.** Do not write English and translate it. Structure the
   sentence the Hebrew way first.
3. **Run the checks** in this file (address, grammar, punctuation, loanwords,
   calques).
4. **Return the copy**, then one line stating the voice, the gender strategy,
   and any assumption you made.

## Pick one voice and hold it

| Voice | Use for | Markers |
|-------|---------|---------|
| Formal (רשמי) | Terms, policies, official letters | Impersonal `יש ל־`, full sentences, no slang |
| Business (עסקי) | B2B email, about pages, proposals | `אנחנו`, clear claims, no padding |
| Direct (ישיר / דוגרי) | Product UI, support replies, startup marketing | Imperative, one idea per sentence, point first, no softeners |
| Casual (יומיומי) | Social, community, chat | Slang allowed (`יאללה`, `סבבה`), emoji sparingly |

Mixing voices inside one piece is the most common flaw. Direct is not rude:
keep `תודה` and basic courtesy, drop the cushioning (`נשמח אם תוכלו לשקול`,
`ייתכן שכדאי`, `אנא`).

## Addressing the reader without guessing gender

Hebrew marks gender on verbs, adjectives and pronouns, so "you" forces a
choice. Prefer, in this order:

1. **Impersonal infinitive** — `יש להזין סיסמה`, `אפשר לבחור תאריך`.
2. **Plural imperative** — `נסו שוב`, `הזינו קוד`, `לחצו לשמירה`. Standard and
   gender-neutral in modern Israeli UI.
3. **Action nouns for buttons** — `שמירה`, `ביטול`, `התחברות`, `המשך`.
4. **Slash forms** (`בחר/י`) — only when nothing else works; they clutter.

One strategy per screen. For buttons, pick either action nouns (`שמירה`) or
imperatives (`שמרו`) per product and keep it consistent. If the product knows
the user's gender and wants personal address, that is an i18n `select`, not a
copy decision (see hebrew-i18n).

## Grammar checks that catch most errors

- **Agreement.** The noun's grammatical gender drives the verb, adjective and
  number. Feminine nouns are the usual trap: `המערכת שולחת`, `האפליקציה
  זמינה`, `השיטה הזאת יעילה`.
- **Construct state (סמיכות).** The definite `ה־` attaches to the last noun
  (`בית הספר`), and the plural goes on the first (`בתי ספר`). Proper names
  take `של`, not construct (`הצוות של דנה`).
- **`את`** marks a definite direct object only: `שלחנו את הקובץ`, `שלחנו קובץ`.
- **Verb-bound prepositions.** `תלוי ב־`, `מתייחס ל־`, `אחראי על`, `מעוניין
  ב־`. Hitpa'el verbs take no `את`: `להתחבר לחשבון`, not `להתחבר את החשבון`.
- **Full spelling (כתיב מלא)**, consistently: `תוכנה`, `שירות`, `תוכנית`,
  `קודם`.

## Numbers, dates and punctuation

- Digits in body copy (`3 ימים`, `תוך 24 שעות`). Spell out only in formal
  text or at the start of a sentence.
- Spelled-out numbers: 1–2 agree with the noun (`יום אחד`, `שתי שעות`); 3–10
  take the form that looks opposite (`שלושה ימים`, `שלוש שעות`). Digits
  sidestep the trap in UI.
- Use the dual where Hebrew has one: `יומיים`, `שעתיים`, `שבועיים`,
  `חודשיים`, `שנתיים` — not `2 ימים` in prose.
- Dates: day before month (`4.3.2026` or `04/03/2026`), 24-hour time
  (`16:30`).
- Geresh `׳` (U+05F3) for abbreviations: `מס׳`, `עמ׳`, `טל׳`. Gershayim `״`
  (U+05F4) before the last letter of an acronym: `צה״ל`, `ת״א`, `מע״מ`. Real
  marks also avoid escaping an ASCII `"` inside JSON translation strings.
- Maqaf `־` (U+05BE) joins a prefix to a digit or Latin word: `ב־2026`,
  `ה־API`. A plain hyphen is common online — pick one per product.
- Ranges use an en dash with no spaces: `10–12`, `16:00–18:00`.
- No nikud in ordinary copy. Add it only for children's content, poetry, or a
  single word that would otherwise be misread.

## English inside Hebrew

For each English term decide: keep, transliterate, or translate.

- **Keep in Latin:** brand and product names, code identifiers, acronyms
  (`API`, `SDK`, `CI`).
- **Transliterate** what people actually say aloud: `באג`, `פיצ׳ר`, `דשבורד`,
  `סטארטאפ`.
- **Translate** where the Hebrew word is the everyday one: `משתמש`, `הגדרות`,
  `הורדה`, `עדכון`, `קובץ`, `לחיצה`.

Loanwords take Hebrew grammar: `באגים`, `הפיצ׳רים`, `הדשבורד נטען` (give each
loanword one gender, usually masculine, and agree with it). A Latin run that
contains spaces or punctuation inside a Hebrew sentence needs bidi isolation in
the markup — see hebrew-rtl-layout.

## Calques to rewrite

| Translated from English | Natural Hebrew |
|-------------------------|----------------|
| `לקחת החלטה` | `להחליט` |
| `זה עושה שכל` | `זה הגיוני` |
| `בסוף היום` | `בסופו של דבר` / `בשורה התחתונה` |
| `לעשות קליק על` | `ללחוץ על` |
| `אתה צריך ללחוץ` (generic you) | `צריך ללחוץ` / `יש ללחוץ` |
| `בכדי לשמור` | `כדי לשמור` |
| `האם ברצונך לשמור את השינויים?` | `לשמור את השינויים?` |
| `אנחנו מתנצלים על אי הנוחות שנגרמה` | `סליחה, משהו השתבש. אנחנו על זה.` (only if true) |

## UI microcopy patterns

- **Errors:** what happened, then what to do. `הסיסמה שגויה. נסו שוב או
  אפסו אותה.` Never blame the user, never show raw codes alone.
- **Confirmations:** label buttons with the action, not `כן` / `לא`:
  `למחוק את הקובץ?` → `מחיקה` / `ביטול`.
- **Empty states:** say what will appear and how to start. `עוד אין כאן
  פרויקטים. אפשר ליצור את הראשון.`
- **Length:** Hebrew strings are rarely the same length as the English
  source. Check truncation in narrow buttons and tabs.

## SEO for Hebrew pages

- Research keywords in Hebrew with the region set to Israel, and cover
  inflections and attached prefixes (`ביטוח`, `ביטוחים`, `לבטח`, `בביטוח`).
- Tech audiences often search in English — include both where natural.
- One H1 with the main term, Hebrew alt text, Hebrew anchor text.
- Slugs: Hebrew (percent-encoded), transliterated, or English — one
  convention per site.

## Commercial messages in Israel

Marketing sent by email, SMS, WhatsApp or automated call is regulated
(section 30A of the Communications Law): it needs the recipient's prior
consent, must be marked `פרסומת` at the start (and in the subject line of an
email), and must identify the sender and offer an easy opt-out. When drafting
a campaign, flag this and tell the user to confirm the current requirements —
this is not legal advice.
