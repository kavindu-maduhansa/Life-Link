# LifeLink API Documentation

This document provides detailed information about the Firebase Firestore collections, document structures, and data flows used in the LifeLink application.

## Table of Contents

- [Overview](#overview)
- [Authentication](#authentication)
- [Firestore Collections](#firestore-collections)
- [Data Models](#data-models)
- [Real-time Streams](#real-time-streams)
- [Security Rules](#security-rules)

## Overview

LifeLink uses Firebase Cloud Firestore as its backend database. All data is stored in collections with specific document structures. The app uses real-time streams to listen for data changes and update the UI accordingly.

## Authentication

### User Authentication Flow

1. User signs in with email/password via Firebase Auth
2. App fetches user document from `users/{uid}` collection
3. Role is extracted from the user document
4. User is routed to the appropriate module based on role

### Supported Roles

- `donor` - Blood donors
- `recipient` - Blood recipients
- `hospital` - Hospital/blood bank staff
- `organisation` - Organization coordinators

## Firestore Collections

### users

Stores user profile information and role assignments.

**Document ID:** User's Firebase Auth UID

**Fields:**
```dart
{
  'email': String,           // User's email address
  'fullName': String,        // User's full name
  'phoneNumber': String?,    // Optional phone number
  'role': String,            // One of: donor, recipient, hospital, organisation
  'createdAt': Timestamp,    // Account creation timestamp
  'updatedAt': Timestamp,    // Last update timestamp
}
```

**Indexes:**
- Query by email (for user lookup)
- Query by role (for admin functions)

### requests

Stores blood donation requests from recipients.

**Document ID:** Auto-generated

**Fields:**
```dart
{
  'recipientId': String,         // UID of the recipient
  'requestType': String,         // 'emergency' or 'scheduled'
  'requestingFor': String,       // 'self' or 'other'
  'patientName': String,         // Patient's full name
  'patientAge': int,             // Patient's age
  'relationship': String?,       // Relationship to patient (if 'other')
  'patientId': String?,          // Patient ID (if applicable)
  'gender': String,              // Patient's gender
  'bloodGroup': String,          // Required blood group (A+, B-, etc.)
  'unitsNeeded': int,            // Number of units required
  'reason': String,              // Reason for request (Surgery, Accident, etc.)
  'hospitalId': String,          // Hospital ID
  'hospitalName': String,        // Hospital name
  'hospitalLocation': String,    // Hospital location
  'wardUnit': String?,           // Ward/unit information
  'doctorClinic': String?,       // Doctor/clinic name
  'urgency': String,             // Urgency level: 'Critical', 'Urgent', 'Normal'
  'bloodNeededBy': String,      // Required by date/time (formatted string)
  'contactNumber': String,       // Contact phone number
  'status': String,              // Request status: 'pending', 'verified', 'matched', 'completed', 'rejected'
  'verifiedDonorsCount': int,   // Number of verified donors
  'createdAt': Timestamp,        // Request creation timestamp
  'updatedAt': Timestamp,        // Last update timestamp
}
```

**Indexes:**
- Query by recipientId (for recipient's requests)
- Query by status (for hospital verification queue)
- Query by bloodGroup (for donor matching)
- Query by urgency (for emergency sorting)
- Composite: status + createdAt (for sorting)

### donors

Stores donor information and availability status.

**Document ID:** User's Firebase Auth UID

**Fields:**
```dart
{
  'userId': String,              // User's Firebase Auth UID
  'fullName': String,            // Donor's full name
  'bloodGroup': String,          // Donor's blood group
  'location': String,            // Donor's location/district
  'phoneNumber': String,         // Contact phone number
  'isAvailable': bool,           // Current availability status
  'lastDonationDate': Timestamp?, // Last donation date
  'totalDonations': int,         // Total number of donations
  'isVerified': bool,            // Verification status
  'createdAt': Timestamp,        // Profile creation timestamp
  'updatedAt': Timestamp,        // Last update timestamp
}
```

**Indexes:**
- Query by bloodGroup (for matching)
- Query by location (for local matching)
- Query by isAvailable (for active donors)
- Composite: bloodGroup + location + isAvailable (advanced matching)

### responses

Stores donor responses to blood requests.

**Document ID:** Auto-generated

**Fields:**
```dart
{
  'requestId': String,           // ID of the request
  'donorId': String,             // UID of the donor
  'donorName': String,           // Donor's name
  'bloodGroup': String,          // Donor's blood group
  'unitsOffered': int,           // Number of units offered
  'responseDate': Timestamp,     // Response timestamp
  'status': String,              // Response status: 'pending', 'accepted', 'rejected', 'completed'
  'hospitalNotes': String?,      // Notes from hospital staff
  'createdAt': Timestamp,        // Response creation timestamp
  'updatedAt': Timestamp,        // Last update timestamp
}
```

**Indexes:**
- Query by requestId (for request's responses)
- Query by donorId (for donor's response history)
- Query by status (for filtering)

### alerts

Stores notifications/alerts for users.

**Document ID:** Auto-generated

**Fields:**
```dart
{
  'recipientId': String,         // UID of the recipient
  'title': String,               // Alert title
  'message': String,             // Alert message
  'type': String,                // Alert type: 'success', 'warning', 'error', 'emergency', 'donor_matched', 'doctor_verified', 'info'
  'isRead': bool,                // Read status
  'relatedRequestId': String?,   // Related request ID (if applicable)
  'createdAt': Timestamp,        // Alert creation timestamp
}
```

**Indexes:**
- Query by recipientId (for user's alerts)
- Query by isRead (for unread alerts)
- Composite: recipientId + isRead (for unread count)
- Composite: recipientId + createdAt (for sorting)

### blood_stock

Stores blood inventory information for hospitals.

**Document ID:** Auto-generated or hospital-specific

**Fields:**
```dart
{
  'hospitalId': String,          // Hospital ID
  'bloodGroup': String,          // Blood group
  'unitsAvailable': int,         // Available units
  'lastUpdated': Timestamp,      // Last inventory update
  'threshold': int,              // Low stock threshold
  'updatedAt': Timestamp,        // Last update timestamp
}
```

**Indexes:**
- Query by hospitalId (for hospital's stock)
- Query by bloodGroup (for specific group)
- Composite: hospitalId + bloodGroup (for specific stock line)

## Data Models

### BloodRequest

```dart
class BloodRequest {
  final String id;
  final String recipientId;
  final String requestType;
  final String requestingFor;
  final String patientName;
  final int patientAge;
  final String? relationship;
  final String? patientId;
  final String gender;
  final String bloodGroup;
  final int unitsNeeded;
  final String reason;
  final String hospitalId;
  final String hospitalName;
  final String hospitalLocation;
  final String? wardUnit;
  final String? doctorClinic;
  final String urgency;
  final String bloodNeededBy;
  final String contactNumber;
  final String status;
  final int verifiedDonorsCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

### Donor

```dart
class Donor {
  final String userId;
  final String fullName;
  final String bloodGroup;
  final String location;
  final String phoneNumber;
  final bool isAvailable;
  final DateTime? lastDonationDate;
  final int totalDonations;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

### Response

```dart
class Response {
  final String id;
  final String requestId;
  final String donorId;
  final String donorName;
  final String bloodGroup;
  final int unitsOffered;
  final DateTime responseDate;
  final String status;
  final String? hospitalNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

## Real-time Streams

The app uses Firestore's real-time capabilities through `StreamBuilder` widgets:

### User Profile Stream
```dart
FirebaseFirestore.instance
  .collection('users')
  .doc(user.uid)
  .snapshots()
```
Updates when user profile changes.

### Requests Stream
```dart
FirebaseFirestore.instance
  .collection('requests')
  .where('recipientId', isEqualTo: user.uid)
  .snapshots()
```
Updates when recipient's requests change status.

### Alerts Stream
```dart
FirebaseFirestore.instance
  .collection('alerts')
  .where('recipientId', isEqualTo: user.uid)
  .snapshots()
```
Updates when new alerts arrive or are marked as read.

### Donor Availability Stream
```dart
FirebaseFirestore.instance
  .collection('donors')
  .doc(user.uid)
  .snapshots()
```
Updates when donor's availability changes.

## Security Rules

Firestore security rules ensure data integrity and access control:

### User Access
- Users can only read their own profile
- Users cannot escalate their role
- Email cannot be modified after account creation

### Request Access
- Recipients can only read their own requests
- Hospital staff can read all requests
- Donors can only read verified requests

### Response Access
- Donors can only read their own responses
- Hospital staff can read all responses
- Recipients can read responses to their requests

### Alert Access
- Users can only read their own alerts
- Users can update their own alert's read status

For detailed security rules, see [`firestore.rules`](../firestore.rules).

## Error Handling

### Common Error Codes

- `permission-denied` - User doesn't have access to the requested data
- `not-found` - Document doesn't exist
- `already-exists` - Document with the same ID already exists
- `failed-precondition` - Query requires an index that doesn't exist
- `unavailable` - Service is temporarily unavailable

### Best Practices

- Always handle error states in the UI
- Show user-friendly error messages
- Implement retry logic for transient errors
- Log errors for debugging

## Performance Considerations

### Query Optimization

- Use indexed fields in where clauses
- Limit query results with `.limit()`
- Avoid large document sizes (>1MB)
- Use pagination for large result sets

### Real-time Stream Management

- Cancel streams when widgets are disposed
- Use `debounce` for rapid updates
- Cache frequently accessed data
- Implement offline support

## Data Validation

### Client-side Validation

- Validate all user inputs before sending to Firestore
- Use form validation for required fields
- Sanitize user input to prevent injection attacks

### Server-side Validation

- Firestore security rules enforce data structure
- Use Cloud Functions for complex validation (if needed)
- Validate data types and ranges

---

For more information, see:
- [LIFELINK_DATA_CONTRACT.md](LIFELINK_DATA_CONTRACT.md)
- [LIFELINK_DESIGN_SYSTEM.md](LIFELINK_DESIGN_SYSTEM.md)
- [Firebase Firestore Documentation](https://firebase.google.com/docs/firestore)
