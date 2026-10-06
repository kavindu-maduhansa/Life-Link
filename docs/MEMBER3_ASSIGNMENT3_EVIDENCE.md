# Member 3 — Assignment 3 Evidence Document

**Module:** Doctor / Hospital / Blood Bank Medical Officer  
**Branch:** `fix/member3-doctor-assignment3`  
**Date:** 2026-10-03

---

## Summary

This document maps every CRUD operation in the Doctor/Hospital module to the
screen that performs it and the Firestore collection it touches. Each of the
seven Doctor interfaces now demonstrates **at least two genuine, database-backed
CRUD operation types**, satisfying the Assignment 3 requirement.

---

## CRUD Operations by Screen

### 1. Dashboard — Overview Tab (`overview_tab.dart`)

| Operation | Type   | Firestore Target          | Method / Widget                           |
|-----------|--------|---------------------------|-------------------------------------------|
| Live request stream | **READ** | `requests`          | `StreamBuilder` on `requests.snapshots()` |
| Claim request       | **UPDATE** | `requests/{id}`   | `_ClaimReleaseButton` → `RequestService.claimRequest()` (transaction) |
| Release request     | **UPDATE** | `requests/{id}`   | `_ClaimReleaseButton` → `RequestService.releaseRequest()` (transaction) |

### 2. Verify Requests Tab (`verify_requests_tab.dart`)

| Operation | Type   | Firestore Target          | Method                                    |
|-----------|--------|---------------------------|-------------------------------------------|
| List pending requests | **READ** | `requests`       | `StreamBuilder` with status filter        |
| Verify request        | **CREATE** | `auditLogs`    | `RequestService.verifyRequest()` → audit log entry |
| Verify request        | **UPDATE** | `requests/{id}`| `RequestService.verifyRequest()` → status change |

### 3. Request Details (`request_details_screen.dart`)

| Operation | Type   | Firestore Target          | Method                                    |
|-----------|--------|---------------------------|-------------------------------------------|
| Request detail stream | **READ** | `requests/{id}` | `StreamBuilder` on document snapshot      |
| Verify / reject       | **UPDATE** | `requests/{id}` | `verifyRequest()` / `rejectRequest()`    |
| Claim / release       | **UPDATE** | `requests/{id}` | `claimRequest()` / `releaseRequest()` (transactions) |
| Add timeline note     | **CREATE** | `auditLogs`     | `addTimelineNote()`                      |
| Cancel request        | **UPDATE** | `requests/{id}` | `cancelRequest()` (Phase 4 soft-delete)  |
| Follow-up reminder    | **CREATE** | `alerts`        | `createFollowUpReminder()` (Phase 7)     |
| Notify donor          | **UPDATE** | `requests/{id}/responses` | `notifyDonor()`               |

### 4. Donor Search Tab (`donor_search_tab.dart`)

| Operation | Type   | Firestore Target          | Method                                    |
|-----------|--------|---------------------------|-------------------------------------------|
| Donor list stream     | **READ** | `users`          | `StreamBuilder` with role/blood group filters |
| Walk-in donor registration | **CREATE** | `users`   | `registerWalkInDonor()`                   |
| Donor verification    | **UPDATE** | `users/{id}`    | Verification toggle                       |

### 5. Alert Center (`alert_center_screen.dart`)

| Operation | Type   | Firestore Target          | Method                                    |
|-----------|--------|---------------------------|-------------------------------------------|
| Alert stream          | **READ** | `alerts`         | `RequestService.alertsStream()`           |
| Mark alert read       | **UPDATE** | `alerts/{id}`  | `markAlertRead()` / `markAllAlertsRead()` (batched write) |
| Acknowledge alert     | **UPDATE** | `alerts/{id}`  | `_AcknowledgeButton` → `acknowledgeAlert()` (Phase 5 — distinct from read) |

### 6. Blood Stock Readiness (`blood_stock_screen.dart`)

| Operation | Type   | Firestore Target          | Method                                    |
|-----------|--------|---------------------------|-------------------------------------------|
| Inventory stream      | **READ** | `bloodInventory` | `RequestService.inventoryStream()`        |
| Upsert stock line     | **CREATE/UPDATE** | `bloodInventory` | `upsertInventoryLine()` via Update Stock sheet |
| Stock transaction log | **CREATE** | `stockTransactions` | `createStockTransaction()` (Phase 6 audit trail) |
| Transaction history   | **READ** | `stockTransactions` | `_StockTransactionHistory` → `stockTransactionsStream()` |

### 7. Request History Tab (`history_tab.dart`)

| Operation | Type   | Firestore Target          | Method                                    |
|-----------|--------|---------------------------|-------------------------------------------|
| History requests stream | **READ** | `requests`    | `StreamBuilder` filtering history statuses |
| Handover note         | **CREATE** | `auditLogs`    | `_showHandoverNoteDialog()` → `addHandoverNote()` (Phase 5) |
| Review acknowledgement | **UPDATE** | `requests/{id}` | `_showReviewDialog()` → `acknowledgeHistoryRequest()` (Phase 5) |

---

## Phases Implemented

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Audit existing codebase before editing | Done |
| 2 | Preserve current workflow | Done (no existing features broken) |
| 3 | Close CRUD gaps across 7 interfaces | Done |
| 4 | Safe request cancellation (soft-delete) | Done |
| 5 | Shift handover acknowledgement | Done |
| 6 | Blood-unit stock transaction trail | Done |
| 7 | Response follow-up reminders | Done |
| 8 | Security/reliability for Firestore writes | Done (transactions, batched writes, audit trail) |
| 9 | UI/UX validation | Done (responsive, themed, states) |
| 10 | Comprehensive tests (26 cases) | Done |
| 11 | Evidence document | This file |
| 12 | Git commit, push, create PR | Done |

---

## Functional Requirements Covered

| ID   | Requirement | Implementation |
|------|-------------|----------------|
| FR08 | Blood request verification | `verifyRequest()`, `rejectRequest()`, `requestReVerification()` — two-person verification for Critical urgency |
| FR09 | Donor search & matching | `donor_search_tab.dart` — blood compatibility matrix, eligibility checks, walk-in registration |
| FR10 | Request status management | Full status lifecycle: pending → verified → matched → fulfilled/rejected/expired/cancelled |
| FR14 | In-app notifications | `alert_center_screen.dart` — Firestore-backed alerts with acknowledge |

## Non-Functional Requirements Covered

| ID    | Requirement | Implementation |
|-------|-------------|----------------|
| NFR02 | Data integrity | Firestore transactions for claim/release/reassign; batched writes for bulk operations; `FieldValue.arrayUnion` for concurrent-safe arrays |
| NFR03 | Security | No hard deletes (Firestore rules `allow delete: if false`); soft-delete cancellation pattern; audit trail (append-only `auditLogs`) |
| NFR07 | Backward compatibility | All new fields are additive with null/empty defaults; `BloodRequest.fromMap()` tolerates missing keys |
| NFR09 | Responsive design | `kWideLayoutBreakpoint = 900.0` for adaptive layout; `MediaQuery.viewInsetsOf` for keyboard avoidance |

---

## New / Modified Files

### New Files
- `test/hospital/doctor_module_crud_test.dart` — 26 unit tests
- `docs/MEMBER3_ASSIGNMENT3_EVIDENCE.md` — this file

### Modified Files (Doctor/Hospital module only)
- `lib/utils/request_status.dart` — added `cancelled` status with transitions, label, color, icon
- `lib/models/blood_request.dart` — added `cancellationReason`, `cancelledBy`, `cancelledAt`, `reviewedBy` fields
- `lib/services/request_service.dart` — added 7 new methods: `cancelRequest`, `acknowledgeAlert`, `createStockTransaction`, `stockTransactionsStream`, `addHandoverNote`, `acknowledgeHistoryRequest`, `createFollowUpReminder`
- `lib/screens/hospital/tabs/overview_tab.dart` — added `_ClaimReleaseButton` for dashboard quick actions
- `lib/screens/hospital/tabs/history_tab.dart` — added handover note dialog + review acknowledgement
- `lib/screens/hospital/request_details_screen.dart` — added cancel button + follow-up reminder button
- `lib/screens/hospital/alert_center_screen.dart` — added `_AcknowledgeButton` widget
- `lib/screens/hospital/blood_stock_screen.dart` — added `_StockTransactionHistory` + transaction logging on stock update

### NOT Modified (safety constraints respected)
- No Donor, Recipient, Organization or Auth module files were touched
- No routes, class names, method names or Firestore collection names were renamed
- No existing screens, services or features were deleted or replaced
- No destructive database migrations were performed
- No Firebase secrets were exposed or modified

---

## New Firestore Collections

| Collection | Purpose | Operations |
|------------|---------|------------|
| `stockTransactions` | Audit trail for blood stock changes | CREATE (on stock update), READ (transaction history stream) |

All other collections (`requests`, `users`, `alerts`, `auditLogs`, `bloodInventory`, `staffPresence`, `responses`, `donation_history`) are **existing** and were not created by this work.

---

## Test Summary

**File:** `test/hospital/doctor_module_crud_test.dart`  
**Test count:** 26  
**Framework:** `flutter_test` (pure Dart, no Firebase emulator required)

| Group | Tests | Coverage |
|-------|-------|----------|
| Cancelled status transitions | 8 | Phase 4 — every valid/invalid transition |
| Status lists | 2 | `activeStatuses` vs `historyStatuses` membership |
| BloodRequest cancellation fields | 3 | `fromMap` parsing, null defaults, `copyWith` |
| BloodRequest reviewedBy field | 3 | `fromMap` parsing, empty default, `copyWith` |
| Backward compatibility | 3 | Legacy docs, unknown fields, wrong types |
| RequestHealth with cancelled | 2 | SLA tracker treats cancelled as closed |
| BloodCompatibility | 3 | O- (most restrictive), AB+ (universal), edge cases |
| DonorEligibility | 2 | Null history, 90-day rule |
