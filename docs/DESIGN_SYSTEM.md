# Aparthub Security Mobile — Design System

> **Status: NORMATIVE VISUAL SOURCE FOR FLUTTER IMPLEMENTATION**  
> This is the most important implementation document for preserving UI consistency across Aparthub Security Mobile. New screens must follow this file unless the approved source-of-truth panels are explicitly revised.

## 1. Design Source of Truth

Two approved presentation boards define the product's visual language:

### Panel A — Visitor Verification

Defines:

- Security Home / Platform Dashboard;
- QR Visitor Verification;
- Manual Visitor Search;
- Visitor Search Results;
- Visitor Detail;
- Check-In Confirmation;
- Check-Out Confirmation;
- Verification History.

### Panel B — Future Operational Modules

Defines:

- Security Platform Home continuity;
- Patrol Management;
- Patrol Route / Checkpoints;
- Incident Reporting;
- Incident Detail;
- Emergency Response;
- Access Control;
- Vehicle Management.

These panels are not inspiration. They are the visual reference that new Flutter screens must remain compatible with.

## 2. Visual Principles

Aparthub Security must feel like:

```text
clean
operational
enterprise
secure
fast to scan
resident/property aware
professional rather than decorative
```

The application must not drift into:

- dark navy-and-gold luxury styling;
- consumer-social styling;
- neon/cybersecurity aesthetics;
- oversized gradients;
- glassmorphism-heavy cards;
- playful rounded illustration systems;
- arbitrary colors per module;
- dense desktop-dashboard layouts squeezed onto mobile.

## 3. Core Color Tokens

Current interpreted Flutter tokens live in:

```text
lib/core/theme/security_tokens.dart
```

These values are derived from the approved panels and remain the working visual contract until official brand tokens are supplied.

| Token | Hex | Usage |
|---|---:|---|
| `primary` | `#073096` | primary action, active navigation, active module emphasis |
| `primaryDeep` | `#082556` | dark scanner surface, deep emphasis |
| `primarySoft` | `#EAF0FF` | selected/supportive blue surface |
| `accent` | `#2F65D9` | secondary blue emphasis |
| `background` | `#F6F8FC` | app/page background |
| `surface` | `#FFFFFF` | cards, sheets, form surfaces |
| `surfaceMuted` | `#F8FAFD` | subtle neutral surface |
| `border` | `#E2E7F0` | card/input separators and outlines |
| `textPrimary` | `#10224B` | headings and primary content |
| `textSecondary` | `#4D5B78` | supporting content |
| `textMuted` | `#7C879F` | helper/meta content |
| `success` | `#22A447` | approved/success/active-positive state |
| `successSoft` | `#EAF8EE` | success chip surface |
| `warning` | `#F59E0B` | pending/warning state |
| `warningSoft` | `#FFF5DF` | warning chip surface |
| `danger` | `#E34949` | expired/rejected/destructive state |
| `dangerSoft` | `#FFECEC` | danger chip surface |
| `info` | `#2F65D9` | checked-in/out informational state |
| `infoSoft` | `#EAF0FF` | info chip surface |

### Color governance

Do not introduce a new arbitrary hex color inside a feature widget if an existing token can express the intent.

A new color may be added only when:

1. the approved visual source clearly requires a distinct semantic role;
2. existing tokens cannot represent it without semantic confusion;
3. it is added centrally to `security_tokens.dart`;
4. this document is updated.

## 4. Surface Hierarchy

Use three main layers:

```text
Page background     #F6F8FC
Primary card        #FFFFFF
Muted/subtle card   #F8FAFD
```

Cards are separated using subtle borders and low-intensity shadows, not high-contrast elevation.

### Standard card treatment

Recommended baseline:

```text
background: surface
border: 1px border token
radius: 12–16px depending on component
shadow: SecurityShadows.soft only where hierarchy needs it
```

Avoid stacking shadow on every nested container.

## 5. Spacing System

Current spacing scale:

| Token | Value |
|---|---:|
| `xxs` | 4 px |
| `xs` | 8 px |
| `sm` | 12 px |
| `md` | 16 px |
| `lg` | 20 px |
| `xl` | 24 px |
| `xxl` | 32 px |

### Spacing rules

- Default mobile horizontal page gutter: **16 px**.
- Major section separation: **20–24 px**.
- Card internal padding: usually **12–16 px**.
- Tight metadata/icon gaps: **4–8 px**.
- Do not use random values unless required to reproduce a specific visual alignment.

Preferred implementation:

```dart
SecuritySpacing.md
SecuritySpacing.lg
```

Avoid repeated magic numbers such as `17`, `19`, `23`, or `27` without a clear reason.

## 6. Radius System

Current radius scale:

| Token | Value | Typical usage |
|---|---:|---|
| `sm` | 8 px | compact controls |
| `md` | 12 px | inputs, buttons, small cards |
| `lg` | 16 px | feature cards, panels |
| `xl` | 20 px | large focus cards/placeholders |
| pill | 999 px | status chips only |

The product uses rounded enterprise geometry, not extreme bubble styling.

## 7. Shadow System

Current shared shadow:

```dart
SecurityShadows.soft
```

Intent:

- low-opacity navy-tinted shadow;
- broad blur;
- minimal visual weight;
- enough separation from pale background.

Use shadow to establish hierarchy, not decoration.

Do not create strong black shadows or multiple elevation layers.

## 8. Typography

Current app uses the platform/system sans-serif through Flutter Material typography. No official brand font file has been provided.

Current semantic scale in `SecurityTheme.light()`:

| Role | Size | Weight | Usage |
|---|---:|---:|---|
| `headlineSmall` | 24 | 700 | rare primary page headline |
| `titleLarge` | 20 | 700 | page/major identity title |
| `titleMedium` | 16 | 600 | section/card heading |
| `bodyLarge` | 16 | regular | prominent body content |
| `bodyMedium` | 14 | regular | standard supporting text |
| `bodySmall` | 12 | regular | metadata/helper text |
| `labelLarge` | 14 | 700 | buttons/important labels |
| `labelMedium` | 12 | 600 | status/support labels |

### Typography rules

- Headings use `textPrimary`.
- Supporting copy uses `textSecondary`.
- Metadata uses `textMuted`.
- Avoid excessive uppercase; reserve it for compact status/eyebrow labels.
- Operational data should be concise and scannable.
- Do not introduce decorative serif/display fonts.

## 9. Page Anatomy

A typical Aparthub Security screen should use:

```text
SafeArea
  ↓
Header / AppBar
  ↓
Primary context
  ↓
Main operational content
  ↓
Primary action where applicable
  ↓
Bottom navigation
```

### Mobile gutter

Use 16 px horizontal gutter as the default.

### Vertical rhythm

Use 20–24 px between major logical sections and 8–16 px within components.

### Scrolling

Prefer vertical scroll for content overflow. Do not reduce text or touch-target size merely to force all content above the fold.

## 10. App Bar and Header

Source-of-truth behavior:

- white or visually integrated header on light screens;
- compact centered title on operational sub-screens;
- back control on nested workflows;
- optional notification/menu affordance only when meaningful;
- no oversized hero app bars.

For the QR scanner, the header may sit over/depend on the dark scanner composition while preserving readable navigation.

## 11. Bottom Navigation

Canonical tabs:

```text
Home
Verify
History
More
```

Rules:

- selected icon/label: primary navy;
- unselected: muted slate;
- fixed navigation layout;
- labels remain visible;
- icon family stays consistent with Material-style outlined/filled operational icons;
- do not rename tabs per screen;
- do not add module-specific tabs to the root bar.

Bottom navigation is a major continuity cue across both source-of-truth panels.

## 12. Buttons

### Primary button

Use for the main operational action:

```text
Check-In Visitor
Check-Out Visitor
Submit Report (future concept)
Start Patrol / Complete Patrol
```

Visual intent:

- Aparthub primary navy fill;
- white text/icon;
- medium radius;
- full-width when the source-of-truth shows an operational CTA;
- strong but not oversized.

### Secondary / outlined button

Use for alternatives such as:

```text
Continue Verifying
Enter Code Manually
Back to Security Home
```

Visual intent:

- white/surface background;
- primary or neutral border;
- primary text;
- same geometry family as primary button.

### Disabled button

Must look intentionally unavailable. Do not rely only on reduced opacity if status context would be ambiguous.

## 13. Inputs and Search

Input baseline comes from `SecurityTheme.inputDecorationTheme`.

Required characteristics:

- white surface;
- subtle border;
- 12 px radius;
- 16 px horizontal content padding;
- clear focus state in primary navy;
- search icon where appropriate;
- placeholder in secondary/muted text.

Manual Visitor Verification search should remain visually simple and fast.

Do not create dense multi-field forms for the active verification path.

## 14. Cards

### Overview metric card

Use for compact dashboard counts.

Structure:

```text
value
label
```

Characteristics:

- white surface;
- subtle border;
- compact height;
- number emphasized;
- status-relevant value color allowed when semantically useful.

### Module card

Structure:

```text
icon
module title
status chip
```

Active Visitor Verification may use strong primary-blue fill/emphasis.

Future modules remain white/soft with Planned/Coming Soon status.

### Visitor result/history card

Structure priority:

```text
Visitor Name               [STATUS]
Visit Code
Resident • Unit • Tower
Date • Validity / activity time                >
```

Do not overpopulate with secondary details that belong on Visitor Detail.

## 15. Status Chips

Status chips are compact pills with semantic foreground/background pairs.

### Visitor statuses

| Status | Semantic treatment |
|---|---|
| Approved | success green |
| Checked-In | informational blue |
| Checked-Out | informational blue |
| Pending | warning orange |
| Expired | danger red |
| Rejected | danger red |
| Cancelled | muted neutral |

### Platform module statuses

| Status | Treatment |
|---|---|
| Active | success green |
| Coming Soon | informational blue |
| Design Concept | muted neutral |

Rules:

- compact uppercase label is allowed;
- status must never be represented by color alone;
- same semantic status uses the same chip treatment everywhere;
- do not invent slightly different chips screen by screen.

## 16. Iconography

Use one coherent icon family. Current implementation uses Flutter Material icons.

Preferred characteristics:

- simple operational line/filled icons;
- consistent stroke/visual weight;
- navy on light surfaces;
- white on active navy surfaces;
- green/orange/red only when communicating state.

Avoid mixing unrelated illustration sets or emoji.

## 17. QR Scanner Surface

QR verification is the intentional visual exception to the predominantly light UI.

Required characteristics:

- deep navy/dark blue background;
- white scan-frame corners;
- high contrast instruction;
- minimal visual noise;
- clear manual verification alternative below/adjacent;
- scanner should look operational, not futuristic/neon.

Do not make the entire application dark just because the QR scanner is dark.

## 18. Confirmation Screens

Check-In and Check-Out confirmations should be visually decisive and calm.

### Check-In

- success green primary confirmation symbol;
- success headline;
- white information card;
- primary `Done` button;
- outlined `Continue Verifying` button.

### Check-Out

- Aparthub blue confirmation symbol as shown by the visual source;
- success headline;
- same information-card geometry;
- same button hierarchy.

Use light celebratory accents sparingly. Do not turn confirmation into a marketing animation.

## 19. Future Operational Modules

Future module presentation screens must inherit the same system:

- same header geometry;
- same bottom navigation;
- same cards;
- same typography;
- same navy primary action;
- same border/radius system;
- semantic colors only for operational states.

Emergency Response may use red as a deliberate exception because danger is semantic, not branding.

Do not create a second visual theme for Patrol, Incident, Access, Vehicle, or Emergency. Operational activation changes behavior, not brand language.

## 20. Layout Consistency Rules

These rules are mandatory for future checkpoints:

1. **16 px default horizontal page gutter.**
2. **Use the shared spacing scale.**
3. **Use shared radii.**
4. **Use shared colors.**
5. **Use existing typography roles before defining custom text styles.**
6. **Cards use subtle border/shadow, never heavy elevation.**
7. **Root bottom navigation remains Home / Verify / History / More.**
8. **Primary CTA uses Aparthub navy.**
9. **Status meaning is consistent across every screen.**
10. **Future modules must look related to Visitor Verification, not like separate apps.**

## 21. Responsive Rules

Primary design target: Android mobile portrait.

Baseline behavior:

- content should remain usable around common 360–430 dp widths;
- no horizontal overflow;
- lists scroll vertically;
- long names use sensible ellipsis/wrapping without hiding status;
- button labels remain readable;
- tablet/wider layouts may constrain content width rather than stretching cards indefinitely.

Do not redesign desktop/tablet layouts until there is a product requirement.

## 22. Accessibility and Operational Usability

Minimum expectations:

- status is communicated with label + color;
- touch targets should remain comfortably tappable;
- contrast must remain strong on primary actions and scanner UI;
- critical action labels must be explicit (`Check-In Visitor`, not `Submit`);
- manual verification remains available when camera/QR is unavailable;
- avoid tiny critical text even if the presentation board visually compresses content.

## 23. Component Reuse Rule

Before styling a new screen, check whether the product already has a reusable pattern for:

- status chip;
- metric card;
- module card;
- visitor card;
- primary/secondary CTA;
- input/search;
- app header;
- confirmation info row;
- bottom navigation.

If the same visual pattern appears twice, prefer a reusable widget or shared theme rule rather than copy-pasting styling.

Do not abstract one-off visual fragments prematurely.

## 24. Visual Regression Checklist

Before declaring a UI checkpoint complete, inspect:

- [ ] White/soft-gray surface hierarchy is preserved.
- [ ] Aparthub navy remains the dominant brand/action color.
- [ ] No new unrelated visual language was introduced.
- [ ] Page gutters and section spacing are consistent.
- [ ] Card radii and borders are consistent.
- [ ] Typography hierarchy matches adjacent screens.
- [ ] Bottom navigation is consistent.
- [ ] Active and Coming Soon modules are visually distinct.
- [ ] Visitor status chips use canonical semantics.
- [ ] QR and Manual Verify are both prominent enough for operations.
- [ ] Main CTA is obvious without overwhelming the page.
- [ ] Empty/loading/error/blocked states still look like the same application.
- [ ] Future module screens do not imply unimplemented backend capability.

## 25. Change Control

A visual change that affects multiple screens must be made in this order:

```text
Approved visual/source decision
        ↓
DESIGN_SYSTEM.md
        ↓
security_tokens.dart / security_theme.dart / shared widget
        ↓
feature screens
        ↓
regression test + visual review
```

Do not patch individual screens with divergent styling to solve a system-wide design issue.

## 26. SEC.4 Operational Detail Patterns

SEC.4 adds three reusable visual patterns that must remain consistent if reused later.

### Visitor Detail information rows

Use a light enterprise card with:

```text
Label                    Value
--------------------------------
Label                    Value
```

Rules:

- label uses muted/body-small hierarchy;
- operational value uses `textPrimary` + semibold weight;
- long values may wrap;
- divider remains subtle;
- do not turn Visitor Detail into a dense form;
- status remains visible near visitor identity.

### Persistent operational action footer

Visitor Detail and action confirmation screens use a persistent bottom action area, separate from vertically scrollable information content.

Rules:

- the primary operational action must remain visible without requiring the officer to discover it at the end of a long detail list;
- Approved detail shows `Check-In Visitor`;
- Checked-In detail shows `Check-Out Visitor`;
- blocked/read-only statuses show their explanatory state in the same footer region;
- confirmation screens keep `Done` and `Continue Verifying` in a persistent footer;
- footer surface stays white with a subtle top border;
- the application bottom navigation remains below this feature-level action area;
- do not duplicate the same CTA inside scrollable content.

This pattern is part of the Visitor Verification source-of-truth interpretation and should be reused for future security operational screens when a single critical action must remain immediately accessible.

### History filter pills

Verification History uses compact horizontal pills:

- selected = Aparthub primary fill + white label;
- unselected = white surface + subtle border + slate label;
- pill geometry is reserved for compact filter/status controls;
- keep one row horizontally scrollable on narrow devices instead of wrapping into a visually noisy grid.

### Confirmation information card

Check-In and Check-Out must share the same confirmation information geometry:

```text
icon  field label
      authoritative/display value
--------------------------------
```

Only the semantic confirmation accent changes:

- Check-In = success green;
- Check-Out = Aparthub primary blue.

`Done` remains the filled primary action and `Continue Verifying` remains the outlined secondary action.

## 27. SEC.5 Future Module Concept Patterns

SEC.5 formalizes reusable presentation patterns from the Future Operational Modules source-of-truth panel.

### Concept notice

Every module that is still presentation-only must expose a compact information banner near the top stating that it is a design concept and does not have active backend/API/hardware automation. Do not show this concept banner on operational Visitor or Patrol screens.

Use:

- `infoSoft` background;
- `info` icon/accent;
- standard `md` radius;
- body-small/slate text;
- no warning-red treatment unless the content itself is an emergency semantic state.

### Future-module header

Use the same compact mobile header geometry as Visitor flows:

```text
back icon     centered module title     reserved trailing space
```

Do not invent module-specific top bars.

### Patrol progress

- progress bar uses Aparthub primary blue;
- completed checkpoint state uses success green;
- pending checkpoint state uses warning orange;
- route/checkpoint cards use normal white enterprise surfaces;
- operational SEC.9 Patrol checkpoint actions use the same button hierarchy as the rest of the app: outlined `Skip`, filled `Mark Complete`; no scanner-style Check-In control is shown.

### Incident presentation

- incident type choices use outlined compact cards;
- selected example may use `primarySoft` + primary outline;
- form fields remain consistent with global input styling;
- evidence placeholder remains neutral and clearly non-live;
- `Submit Report` stays disabled until the module becomes operational.

### Emergency semantic exception

Emergency Response may use:

```text
danger
dangerSoft
```

for the emergency region and SOS control because red communicates danger semantics.

Do not propagate red into the rest of the application or create a separate Emergency theme.

The SOS presentation control must include explicit non-operational copy while the module is a concept.

### Access state cards

Access cards use the standard enterprise surface and canonical semantic states:

- Active = success green;
- Inactive = danger red;
- lock/unlock icons supplement labels but never replace them.

### Vehicle cards

Vehicle presentation follows the same information-row geometry as Visitor Detail:

```text
Field label                 Value
```

Registration/access states use semantic chips rather than custom vehicle-specific colors.

### More / module catalog

The More tab may expose a module catalog using the same module icon family, status chips, card radius, border, and typography as Home.

Visitor Verification, Patrol Management, Incident Reporting, Emergency SOS, and Package Receiving are visually `ACTIVE`. The broader hardware-dependent Emergency surface, Access Control, and Vehicle remain concept/HOLD until separately activated.

### Concept drill-down footer

For modules that remain presentation-only, a single safe navigation CTA that moves deeper into the same concept may use the same persistent footer geometry as operational actions when keeping the next step visible materially improves clarity.

Rules:

- the footer is only for navigation/presentation, not for pretending that a future operation is active;
- future actions such as Incident Submit before SEC.10, SOS escalation, access hardware commands, and vehicle gate commands remain disabled or non-operational;
- footer surface stays white with a subtle top border and standard horizontal spacing;
- do not duplicate the same CTA inside scrollable content;
- long informational sections remain scrollable independently above the footer.

## 28. SEC.7 Authentication Surface

Security login is part of the same Aparthub visual system; it is not a separate brand surface.

Use:

- soft gray application background;
- centered white enterprise card with standard `xl` radius, subtle border, and soft shadow;
- Aparthub primary-soft shield/icon container;
- standard global text-field geometry;
- one filled Aparthub-primary `Sign In` CTA;
- inline semantic danger text for authentication failure;
- no dark login redesign, gradients, gold accents, or module-specific typography.

On narrow/mobile devices the card must remain vertically scrollable and horizontally constrained by normal page spacing. Authentication UI may introduce only components that are reusable with the existing field/button system.


## SEC.8 Scanner and Runtime Error Patterns

### Live QR scanner

API-mode camera preview must remain visually inside the existing dark scanner frame. The device camera is infrastructure, not a reason to redesign the screen.

Required visual states:

- camera initializing → centered progress indicator inside scanner frame;
- active scan → live preview + existing high-contrast corner overlay;
- verification in flight → dark translucent processing overlay + progress indicator;
- camera unavailable/permission denied → dark scanner surface + explicit icon/message;
- manual verification CTA remains visible below all scanner states.

Flashlight control stays in the scanner header and may show an operational error if the device does not support torch mode.

### Retryable data error

For screen-level data such as Verification History:

```text
icon
short title
concise operational message
Retry CTA
```

Do not replace a failed data load with an empty-state message. Empty means a successful request returned no records; error means the request did not complete successfully.


## 29. SEC.9 Operational Patrol Patterns

Patrol graduates from SEC.5 concept to operational UI without introducing a new visual system.

### Dashboard cards

- use existing white/surface cards, subtle border and `SecurityShadows.soft`;
- active/next Patrol may use `primarySoft` or primary emphasis;
- route name is primary, session number/property/time are metadata;
- progress uses the existing primary progress indicator, never a new gradient.

### Patrol status chips

```text
Scheduled    → info / blue
In Progress  → warning / amber
Completed    → success / green
Cancelled    → neutral / slate
```

### Checkpoint status chips

```text
Pending    → warning
Completed  → success
Skipped    → neutral
Issue      → danger
```

These are visual mappings only; exact wire values remain owned by the backend contract.

### Checkpoint card

Use:

- numbered circular sequence marker;
- name + code/location hierarchy;
- compact status pill;
- checked timestamp/officer only when present;
- optional notes;
- `Skip` outlined secondary action;
- `Mark Complete` filled primary action.

Do not show fake scanner, GPS, NFC or device-proof affordances.

### Persistent Patrol action footer

Use the same validated operational geometry as Visitor Detail:

```text
scrollable operational content
        ↓
persistent bottom action footer
```

`Start Patrol` and `Complete Patrol` belong in this footer so the main action remains visible and testable. Disabled completion may communicate remaining Pending checkpoints rather than disappearing.

### Cross-module consistency

Visitor and Patrol are both operational after SEC.9, but must still look like one application: same gutters, radius, status-chip weight, button height, typography, header geometry, bottom navigation and error/empty/loading language.

## Localization / Copy Rules (SEC.9A)

- Bahasa Indonesia and English share the same layouts, tokens, hierarchy, iconography, and status-chip visual language.
- UI components must allow longer translated labels without introducing a separate visual language.
- Do not hard-code production presentation copy when an ARB key exists.
- Canonical API/database wire values are not user-facing translation resources; translate only their presentation labels.
- Proper names, identifiers, visit codes, incident numbers, plate numbers, and backend-owned data remain data, not translated copy.



## 30. SEC.10 Operational Incident Patterns

- Preserve the same white/surface card system, Aparthub navy emphasis, rounded enterprise geometry, and compact chips used by Visitor and Patrol.
- Incident status chips: Open info-blue; Acknowledged amber; In Progress primary navy/blue; Resolved green; Closed slate; Cancelled red. These are presentation mappings only.
- Severity chips: Low green; Medium blue; High amber; Critical red.
- Lifecycle actions remain in a persistent bottom footer on Incident Detail, matching the proven Visitor/Patrol operational geometry.
- Timeline cards show event label, optional from/to status, notes, actor, and locale-aware timestamp.
- Create Incident must not show photo/video affordances because media upload is outside Incident V1.
- If more than one authorized property exists, use a standard dropdown selector; it is context selection, not an authorization control.


### SEC.11 Patrol-linked Incident CTA

Use a full-width outlined `Report Issue` / `Laporkan Masalah` action inside an eligible Pending checkpoint card, above the existing Skip/Mark Complete row. This preserves the existing primary-action hierarchy and prevents three compressed horizontal buttons. Incident Create shows a standard informational notice identifying the linked checkpoint/session; it must not introduce a new visual language.


## SEC.11A Localization Transport / Copy Alignment

- Visual localization remains ARB-driven; API `Accept-Language` does not replace client-owned UI copy.
- Backend `message` text can be shown as helper/error copy but must never control styling, state transitions, or navigation.
- `Content-Language` is response metadata, not a domain status.
- Security status labels should match the APH.35C/APH.37 catalog while retaining the existing status-chip semantic colors and geometry.
- The SEC.12 Emergency SOS modal may use the existing semantic-danger/red exception, but must remain within the Aparthub white/gray/navy visual system rather than introducing a separate emergency theme.

## Emergency SOS Status Language

Emergency uses the existing enterprise card/chip system with urgency reserved for active `Open` SOS. Canonical values remain transport-only; display labels are localized: `Open` → `Terbuka`, `Acknowledged` → `Diambil Security`, `Resolved` → `Selesai`. The persistent modal uses the existing rounded card, subtle border/shadow system with danger emphasis; it does not introduce a separate visual language.


## SEC.13 Package Receiving Patterns

Package Receiving reuses the same white/soft-gray surfaces, Aparthub navy primary, rounded enterprise cards, subtle border/shadow system, compact status chips, and persistent bottom-action geometry as Visitor/Patrol/Incident/Emergency. Package status display colors are semantic presentation only: `Ready for Pickup` uses info/blue, `Collected` success/green, and `Expired` warning/amber. Resident search results use selectable bordered cards; selected Resident context is confirmed with a success-soft card. Do not introduce courier-brand styling, scanner UI, package-photo capture, or smart-locker visuals without a later explicit contract.
