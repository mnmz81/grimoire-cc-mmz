---
name: hebrew-i18n
description: >
  Hebrew localization for web apps, Angular first — @angular/localize builds,
  ICU plurals with Hebrew's one/two/other categories, he-IL dates, numbers and
  shekel formatting (Intl and Angular pipes), Hebrew calendar dates, Israeli
  phone and ID-number handling, translation-key hygiene, gender-aware
  messages, and testing formatted strings. Use when adding Hebrew to an app,
  fixing Hebrew plurals, formatting Israeli dates or currency, setting up
  i18n (Angular i18n, Transloco, ngx-translate, any ICU library), or when
  Hebrew strings break snapshot or equality tests. Layout and direction bugs
  go to hebrew-rtl-layout; wording goes to hebrew-copywriting.
---

# Hebrew i18n

Hebrew differs from English in four places that break naive i18n: it has a
dual plural, it is right-to-left, its formatted numbers carry invisible
direction marks, and its grammar changes with gender and attached prefixes.
Handle each explicitly.

## 1. Locale and direction

Every Hebrew page needs `lang="he"` and `dir="rtl"` on `<html>`, not on a
wrapper element. In Angular, set both from the active locale at startup:

```ts
// app.config.ts
import { DOCUMENT, LOCALE_ID, inject, provideAppInitializer } from '@angular/core';

export const appConfig = {
  providers: [
    provideAppInitializer(() => {
      const doc = inject(DOCUMENT);
      const locale = inject(LOCALE_ID);
      doc.documentElement.lang = locale;
      doc.documentElement.dir = locale.startsWith('he') ? 'rtl' : 'ltr';
    }),
  ],
};
```

Build-time localization (`@angular/localize`): add the locale to
`angular.json` and turn on `localize` for the build, otherwise no Hebrew
bundle is produced.

```jsonc
// angular.json → projects.<app>
"i18n": {
  "sourceLocale": "en",
  "locales": { "he": "src/locale/messages.he.xlf" }
},
// architect.build.options
"localize": true
```

Extract with `ng extract-i18n`. If the language switches at runtime without a
reload (Transloco, ngx-translate), also update `lang`/`dir` on every switch and
read hebrew-rtl-layout §1: Angular CDK does not notice a later change to
`<html dir>` on its own.

## 2. Plurals: one, two, other

Hebrew's CLDR plural categories are exactly `one`, `two` and `other`. Both
`Intl.PluralRules('he')` and Angular's `he` locale data agree:

| Count | Category | Example |
|-------|----------|---------|
| 1 | `one` | `הודעה אחת` |
| 2 | `two` | `שתי הודעות` / dual `יומיים` |
| 0, 3+, 11, 20, 100 | `other` | `5 הודעות` |
| 0.5 | `one` (!) | give fractions their own wording: `חצי שעה` |
| 1.5, 2.5 | `other` | `1.5 שעות` |

Do not write a `many` branch: it belonged to older CLDR data and never matches
today. Add `=0` when zero deserves its own sentence.

**Angular template (ICU):**

```html
<span i18n="@@inbox.unreadCount">
  {count, plural,
    =0 {אין הודעות חדשות}
    one {הודעה חדשה אחת}
    two {שתי הודעות חדשות}
    other {{{count}} הודעות חדשות}}
</span>
```

ICU syntax is the same in other ICU-based libraries (Transloco with its
messageformat plugin, ngx-translate with a messageformat compiler); only the
interpolation braces differ (`{count}` instead of Angular's `{{count}}`).

**TypeScript code:** `$localize` does not support ICU, so pick the form with
`Intl.PluralRules`:

```ts
type HePluralForms = { one: string; two: string; other: string; zero?: string };
const heRules = new Intl.PluralRules('he');

export function hePlural(count: number, forms: HePluralForms): string {
  if (count === 0 && forms.zero) return forms.zero;
  const category = heRules.select(count) as 'one' | 'two' | 'other';
  return forms[category].replace('#', String(count));
}

hePlural(2, { one: 'יום אחד', two: 'יומיים', other: '# ימים' }); // "יומיים"
```

Units with a dual form — use it in the `two` branch:

| one | two | other |
|-----|-----|-------|
| `דקה אחת` | `שתי דקות` | `# דקות` |
| `שעה אחת` | `שעתיים` | `# שעות` |
| `יום אחד` | `יומיים` | `# ימים` |
| `שבוע אחד` | `שבועיים` | `# שבועות` |
| `חודש אחד` | `חודשיים` | `# חודשים` |
| `שנה אחת` | `שנתיים` | `# שנים` |

Spelled-out numbers 3–10 flip their gender-looking form (`שלושה ימים`,
`שלוש שעות`); keep digits in `other` branches to avoid the trap.

## 3. Dates and time

| What | Code | Output for 4 March 2026 |
|------|------|-------------------------|
| Intl numeric | `new Intl.DateTimeFormat('he-IL', { day: '2-digit', month: '2-digit', year: 'numeric' })` | `04.03.2026` |
| Intl long | `new Intl.DateTimeFormat('he-IL', { dateStyle: 'long' })` | `4 במרץ 2026` |
| Angular `DatePipe` | `date:'shortDate'` with `he` locale | `4.3.2026` (no leading zeros) |
| Explicit slashes | `date:'dd/MM/yyyy'` | `04/03/2026` |
| Hebrew calendar | `new Intl.DateTimeFormat('he-IL-u-ca-hebrew', { dateStyle: 'long' })` | `ט״ו באדר תשפ״ו` |

- `he-IL` alone uses the Gregorian calendar; the Hebrew calendar needs the
  `-u-ca-hebrew` extension. Keep Gregorian for anything filed with an
  authority.
- The week starts on Sunday and the weekend is Friday–Saturday. Check that
  date pickers render Sunday first; with Angular Material set
  `MAT_DATE_LOCALE` to `he-IL` and confirm the first column.
- Time is 24-hour (`16:30`).
- Pick dot or slash separators once per product and use them everywhere,
  including validation messages and placeholders.

## 4. Numbers, currency, phones and IDs

- Grouping comma, decimal point: `1,234,567.89`.
- **Formatted shekel amounts are not plain text.** `Intl.NumberFormat('he-IL',
  { style: 'currency', currency: 'ILS' })` returns `1,234.50 ₪` with RIGHT-TO-LEFT
  MARKs (U+200F) before the digits and the sign and a NO-BREAK SPACE (U+00A0);
  negatives add a LEFT-TO-RIGHT MARK (U+200E) before the minus. Angular's
  `he` currency pattern contains the same marks. Consequences:
  - Never parse a formatted value back into a number — keep the raw number.
  - Normalize before comparing strings in tests or exporting CSV:

    ```ts
    export const plainText = (s: string): string =>
      s.replace(/[‎‏]/g, '').replace(/ /g, ' ');
    ```
  - Do not force `dir="ltr"` on this output; isolate it instead (see
    hebrew-rtl-layout §4).
- **Phones:** mobile `05X-XXXXXXX`, landline `0X-XXXXXXX`; internationally
  `+972` and drop the leading `0`. Use `<input type="tel">`.
- **Postal code:** 7 digits.
- **ID number (תעודת זהות):** up to 9 digits with a check digit. Validate
  rather than only counting digits:

  ```ts
  export function isValidTeudatZehut(raw: string): boolean {
    const id = raw.trim();
    if (!/^\d{5,9}$/.test(id)) return false;
    const sum = [...id.padStart(9, '0')].reduce((acc, ch, i) => {
      const step = Number(ch) * ((i % 2) + 1);
      return acc + (step > 9 ? step - 9 : step);
    }, 0);
    return sum % 10 === 0;
  }
  ```

## 5. Message hygiene

- **Stable IDs.** Give every Angular message a custom ID
  (`i18n="@@checkout.payButton"`) so editing the English text does not orphan
  the Hebrew translation. In key-based libraries use semantic keys
  (`checkout.payButton`), never the English sentence.
- **Context for translators.** Use `i18n="meaning|description@@id"` and state
  who is addressed and how: `button; addresses the user; plural imperative`.
- **No sentence assembly.** Never build a sentence from fragments. Hebrew
  word order differs and prefixes (`ב`, `ל`, `ה`, `ו`, `ש`, `מ`) attach to the
  next word, so `'ב' + cityName` or `'ה' + productName` breaks with Latin
  names and with names that already carry a prefix. Put the whole sentence in
  one message with placeholders.
- **Gendered address.** When the product knows the user's gender and wants
  personal address, use ICU `select`, with `other` as the neutral fallback:

  ```html
  <span i18n>{gender, select,
    female {ברוכה הבאה, {{name}}}
    male {ברוך הבא, {{name}}}
    other {שלום, {{name}}}}</span>
  ```
- **Latin names in Hebrew messages.** Keep brand and product names as
  placeholders so they can be bidi-isolated in the template.

## 6. Test checklist

- Plurals at 0, 1, 2, 3, 11 and 0.5.
- Dates in every format the app shows, including date pickers (Sunday first).
- Currency strings compared through `plainText`; no `parseFloat` on formatted
  output.
- A Hebrew build or locale switch with long and short strings to catch
  truncation.
- Snapshot tests: normalize U+200E/U+200F/U+00A0 or snapshot raw values.
