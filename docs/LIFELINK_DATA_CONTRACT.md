# LifeLink data contract

**Scope:** the Firestore collections and fields the Doctor / Blood Bank module
(Member 3) reads and writes, and the compatibility decisions it makes where the
team's modules disagree about a field name.

**Audience:** the whole LifeLink team. Everything below describes the *current*
state of the code in this repository, not a plan. Where a mismatch exists it is
named rather than quietly worked around, so the team can decide on a single
canonical shape.

Last reviewed: 12 September 2026, against branch `feat_Member3_DoctorM`.

---

## 1. Collections in use

| Collection | Written by | Read by the Doctor module | Notes |
|---|---|---|---|
| `users` | `register_screen.dart` (sign-up), `RequestService.registerWalkInDonor` | Donor search, Command Palette, dashboard donor counts | One document per account. `role` selects the module. |
| `requests` | Recipient module (creation), Doctor module (verification, fulfilment, assignment, escalation) | Every Doctor screen | The shared request document. See section 3. |
| `requests/{id}/responses` | Doctor module | Request details, donor history | One document per donor notified for that request. |
| `auditLogs` | Doctor module only | Request timeline | Append-only. Never updated or deleted. |
| `alerts` | Doctor module only | Alert Centre | Deterministic document ids prevent duplicates. See section 6. |
| `bloodInventory` | Doctor module only | Blood Stock Readiness | **New in this milestone.** No other module touches it. See section 5. |

---

## 2. Donor availability - the one real mismatch

### The problem

Three different states existed in the data, and the code collapsed them into two.

| Where | Field written | Value |
|---|---|---|
| `register_screen.dart` (app sign-up) | *none* | - |
| `RequestService.registerWalkInDonor` (walk-in) | `availableNow` | `true` |
| Donor module (intended canonical) | `isAvailable` | `true` / `false` |

The Doctor module previously read availability as:

```dart
final available = data['availableNow'] != false; // missing = assumed available
```

`!= false` resolves a **missing** field to `true`. Every donor who signs up
through the app has no availability field at all, so every one of them was
presented to blood-bank staff as available to donate right now - on no evidence.
For a blood bank that is the wrong direction to fail in: it sends staff calling
people who never said they were available, and it inflates the "Available" and
"Verified Donors" counts on the dashboard.

### The decision

`isAvailable` is the **canonical** field. `availableNow` is **legacy** and is
still read so existing walk-in records keep working.

Resolution order, implemented once in `lib/utils/donor_availability.dart` and
used by every Doctor-side screen:

1. `isAvailable` - if it holds a **boolean**, use it.
2. `availableNow` - if it holds a **boolean**, use it.
3. Otherwise -> **`DonorAvailability.unknown`**.

Rules that follow from that:

- **A missing field is never treated as available.** It is `unknown`.
- A present-but-non-boolean value (for example the string `"true"` typed into
  the Firebase console) is *not* guessed at; the reader falls through to the
  next field, and reports `unknown` if neither yields a boolean.
- The Doctor module **does not dual-write** both fields, and **does not migrate**
  donor documents. It is a read-side adapter only.
- The "Available only" filter passes **only** confirmed-available donors. Its
  promise to staff is "these people said yes", not "these people did not say no".
- The Match Score awards availability points **only** for confirmed available.
- Sort order is: confirmed available -> unknown -> confirmed unavailable.
  Unknown sorts above unavailable because it is worth a phone call.
- The donor list shows a banner counting how many loaded records carry no
  availability field, so the size of the gap is visible rather than implied.

Applied consistently across donor search, donor cards, donor comparison, the
donor profile sheet, smart matching, and the dashboard's "Verified Donors" stat.

### What the team still needs to decide

1. Should `register_screen.dart` collect availability at sign-up, or should the
   Donor module set `isAvailable` on first launch? Until one of those happens,
   every app-registered donor legitimately reads as `unknown`.
2. Should the walk-in registration path switch from `availableNow` to
   `isAvailable`? That is a one-line change in `RequestService`, but it is a
   **shared** write path, so it is left for the team rather than changed
   unilaterally here.

---

## 3. The `requests` document

### Fields owned by the Recipient module (read as-is, never written here)

`patientName`, `bloodGroup`, `unitsNeeded`, `urgency`, `hospitalName`,
`location`, `notes`, `createdBy`, `createdByName`, `createdAt`

### Fields owned by the Doctor module

| Field | Type | Meaning |
|---|---|---|
| `status` | string | `pending` / `verified` / `matched` / `fulfilled` / `rejected` / `expired` |
| `verifiedBy`, `verifiedAt` | string, timestamp | Verification record |
| `rejectionReason` | string | Set on rejection |
| `unitsConfirmed`, `donorsNotifiedCount`, `donorsAcceptedCount` | int | Denormalised counters, recomputed from `responses` |
| `pinnedBy` | array of string | Doctor uids who pinned the request |
| `firstApproverId`, `firstApproverName`, `firstApprovedAt` | string, string, timestamp | First co-sign on a Critical request |
| `secondApproverId`, `secondApproverName` | string | Second, independent co-sign |

### Added in this milestone - all optional, all backward compatible

Clinical detail. The Recipient module does not collect these yet, so today they
are normally absent and the UI renders **"Not recorded"**. They are never
invented to fill a gap.

`patientReference`, `ward`, `requiredAt`, `bloodComponent`,
`requestingOfficerName`, `contactExtension`, `crossmatchStatus`, `hospitalId`,
`clinicalNotes`

Ownership: `assignedDoctorId`, `assignedDoctorName`, `assignedAt`

Escalation: `escalationLevel`, `escalatedAt`, `escalationNote`

**Backward compatibility is enforced by tests.** `BloodRequest.fromMap` parses a
document containing none of these keys - and a completely empty document - into
a complete object with nulls and safe defaults. See
`test/models/blood_request_test.dart`.

### Request ID is not a Patient ID

The request details screen previously labelled the Firestore **document id** as
`Patient ID`. It is not one: it identifies the request, not the person. It is
now labelled **Request ID**, and `patientReference` (the hospital's own patient
identifier) is displayed as a separate row that reads "Not recorded" when the
field is absent.

---

## 4. Request assignment

Rules live in `lib/utils/request_assignment.dart`; the Firestore writes live in
`RequestService.claimRequest` / `releaseRequest` / `reassignRequestToMe`.

- A request may be **claimed** only while `assignedDoctorId` is absent or empty.
- A request may be **released** only by the operator who holds it.
- **Reassignment** (taking over a colleague's request) requires an explicit
  confirmation in the UI that names the current owner. There is no seniority or
  permission data on the `users` document that would justify a silent override,
  so the action is deliberately conservative and always audited.

### Why a transaction

Two operators tapping "Assign to me" on the same request at the same moment is a
realistic blood-bank scenario. A plain `update()` would let the second write win
silently, and the first operator would believe they owned a request they did
not. The claim re-reads the document **inside** a Firestore transaction, so the
loser receives a `conflict` outcome naming the current owner, and **nothing is
written**.

> **Stated limitation:** the concurrency guarantee here is Firestore's
> transaction semantics. The unit tests cover the *rules* (who may claim what,
> and what each outcome means). They do **not** simulate two concurrent clients -
> that would need the Firestore emulator, which is not set up in this
> repository. This is a genuine gap, named rather than papered over.

---

## 5. `bloodInventory` (new collection)

One document per facility + blood group + component. Document id is
`{facilityId}_{bloodGroup}_{component}`, sanitised - so updating the same line
twice edits one document instead of creating duplicate rows.

| Field | Type | Meaning |
|---|---|---|
| `facilityId` | string | Which hospital / blood bank |
| `bloodGroup` | string | Normalised to upper case on read |
| `component` | string | Whole Blood / Packed Red Cells / Platelets / Fresh Frozen Plasma / Cryoprecipitate |
| `availableUnits` | int | Units physically on the shelf |
| `reservedUnits` | int | Units already promised to a request |
| `minimumThreshold` | int | `0` means "no minimum recorded" |
| `expiryRiskUnits` | int | Units close to expiry, recorded by staff |
| `updatedAt` | timestamp | Server timestamp on write |
| `updatedBy` | string | Who recorded it |

### Readiness policy (`lib/utils/stock_readiness.dart`)

Usable units = `availableUnits - reservedUnits`, floored at 0.

| Condition | Level |
|---|---|
| usable <= 0 | Out of stock |
| no `minimumThreshold` recorded | **No minimum set** - not scored |
| usable < 50% of minimum | Critical shortage |
| usable < minimum | Low stock |
| usable >= minimum | Adequate |

Freshness is judged from `updatedAt` alone: within 24 h -> current; older ->
**possibly out of date**; absent -> **never recorded**. A stale or
never-recorded line is flagged even when its numbers look healthy, because a
figure nobody has touched in days is not evidence of what is on the shelf right
now.

A document claiming more reserved than available units is surfaced as an
explicit **data problem** and treated as 0 usable, rather than showing a
negative count.

**No seeded or demo stock.** An empty collection renders an empty state that
explains how authorised staff add a line. LifeLink never estimates stock.

---

## 6. `alerts`

Existing types (unchanged): `donor_accepted`, `donor_declined`,
`critical_request`, `pending_verification`.

Added: `unassigned_urgent`, `low_stock`, `stale_request`, `request_escalated`.

Each type maps to exactly one primary action (`lib/utils/alert_actions.dart`):

| Type | Action |
|---|---|
| `critical_request` | Open request |
| `request_escalated` | Open request |
| `pending_verification` | Open verify queue |
| `donor_accepted` / `donor_declined` | Open donor matches |
| `unassigned_urgent` | Assign to me |
| `low_stock` | Open stock readiness |
| `stale_request` | Open request timeline |

An unrecognised type - including one a teammate adds later - degrades to "open
the request" when it carries a `requestId`, and to "mark as read" otherwise, so
a new alert type is never silently unusable. An alert whose referenced request
has since been deleted shows an explanatory notice instead of a button that goes
nowhere.

Duplicates are prevented by deterministic document ids, so the same detection
running on several doctor devices merges onto one document.

`readBy` is an array of uids. A missing or malformed `readBy` reads as unread
rather than throwing.

---

## 7. Notifications - what LifeLink does and does not do

**LifeLink sends no SMS, no email, and no push notifications.** There is no FCM
integration, no mail transport and no telephony integration in this repository.

"Alerts" are Firestore documents rendered by the in-app Alert Centre. Nothing
leaves the app.

Accordingly, the escalation workflow records a **response attempt** - what a
human actually did - and its default outcome is **"Manual follow-up required"**.
No label anywhere in the module claims a message was sent. This is enforced by a
test that asserts no `ResponseAttemptOutcome` label contains "sms", "email",
"notification" or "sent".

---

## 8. Privacy

Donor phone numbers are **masked by default** in lists and cards
(`lib/utils/donor_privacy.dart`), revealed only after an explicit confirmation
that states the reveal is audited, and the reveal is written to `auditLogs`.

> **This is presentation-layer minimisation, not a security control.** The full
> Firestore document is still delivered to the client, so masking in the UI does
> **not** replace Firestore security rules or backend authorisation. Anyone with
> the client can read the underlying field.

### Recommended Firestore rule improvements - NOT deployed by this work

These are suggestions for the team to review and apply deliberately. This
milestone does **not** deploy rules.

1. Restrict `users` reads so a Doctor-role account can read the donor fields it
   needs for coordination (`fullName`, `bloodGroup`, `location`, `verified`,
   availability, `lastDonationDate`) without the whole document - either via a
   separate projection collection or per-field rules.
2. Restrict `phoneNumber` to Doctor/Coordinator roles only.
3. Make `auditLogs` **create-only** for all clients - no update, no delete - so
   the audit trail cannot be rewritten from a client.
4. Restrict `bloodInventory` writes to Doctor/Coordinator roles.
5. Restrict the assignment and escalation fields on `requests` to Doctor-role
   accounts, so a Recipient client cannot assign or escalate.

---

## 9. Known integration limitations

1. **Availability field split** (section 2) - needs a team decision.
2. **No concurrency test against a real database** (section 4) - the Firestore
   emulator is not configured in this repository.
3. **Clinical fields are not collected anywhere yet** (section 3). The Doctor
   module displays them and renders "Not recorded" until request creation
   captures them. The Recipient module owns that form.
4. **Four pre-existing test failures** in `test/widget_test.dart`. They assert
   placeholder text (`"Hospital Area"`, `"Donor Area"`, ...) that the screens no
   longer contain, and the Donor/Recipient/Coordinator screens additionally read
   `FirebaseAuth.instance.currentUser` during `build`, which throws without
   `Firebase.initializeApp()`. These predate this milestone and touch other
   members' screens, so they are reported rather than rewritten here.
5. **No Firestore composite indexes are required** by the queries added in this
   milestone. `inventoryStream` uses at most a single-field `where` plus a
   `limit`, and sorting is done client-side. (The pre-existing duplicate-request
   check in `findPossibleDuplicates` may prompt for an index on first run; that
   behaviour is unchanged and is already handled by a try/catch.)

---

## 10. Manual testing steps

No Firebase project changes are required to try any of this.

1. **Legacy request still opens.** Open any request created before this
   milestone. The Clinical Request Summary should render with "Not recorded" in
   the clinical rows and no crash.
2. **Request ID vs Patient Reference.** On that same screen, confirm the first
   row reads **Request ID** (the long Firestore id) and **Patient Reference** is
   a separate row.
3. **Assignment.** Tap "Assign to me". The card should switch to "Assigned to
   you" with a timestamp. Tap "Release assignment" to hand it back.
4. **Assignment conflict.** Sign in on a second device/account, open the same
   request, and tap "Assign to me" on both at once. Exactly one succeeds; the
   other gets a message naming the operator who won. Nothing is overwritten.
5. **Escalation.** Set the level to Urgent with a reason. Confirm it appears in
   the audit timeline with both levels and the reason. Try Critical - it should
   demand a confirmation.
6. **Escalation validation.** Try to submit with an empty or 2-character
   reason; both should be refused with a specific message.
7. **Donor availability.** Open Donor Search. A donor registered through the app
   (no availability field) should show **"Availability unknown"** in amber, not
   "Available", and should be excluded by the "Available only" filter.
8. **Blood stock.** Open Blood Stock Readiness from the dashboard card. With an
   empty collection it should show the empty state. Record a line with 2 units
   on shelf and a minimum of 10 - it should read **Critical shortage**.
9. **Verify search.** In Verify Requests, search a partial request ID, a ward,
   or a blood group. The result count line should read "N of M requests match".
   Clearing with the x restores the full queue.
10. **Ownership filter.** Switch between All / Assigned to me / Unassigned.
11. **Alerts.** Open the Alert Centre. Each alert should show a verb-first
    action line ("Open request", "Open stock readiness", ...).
12. **Narrow phone.** Run at 400dp width. The app bar title must truncate with
    an ellipsis - no yellow-and-black overflow stripe - and the Handover and
    Appearance actions move into the overflow menu.
13. **Light and Dark.** Switch appearance. Light Mode should be warm porcelain
    with burgundy actions and teal secondary actions; Dark Mode unchanged.

---

## 11. Screens and routes added

| Screen | How it is reached |
|---|---|
| `BloodStockScreen` | "Open" on the dashboard's Blood Stock Readiness card, the `low_stock` alert action, and the empty-state button |

No named routes were added, and no existing route was changed or removed.
