# Cloud Functions - WorkNow Notification System

## Overview

This directory contains Firebase Cloud Functions that power the notification system for the WorkNow app.

## Functions

### `onJobCreated`

Triggers when a new job is created in Firestore. This function:

1. Finds users whose interests/skills match the job category
2. Finds users whose location matches the job location
3. Creates notification documents in each matching user's subcollection
4. Sends FCM push notifications to users with valid tokens
5. Handles invalid tokens by removing them from user documents

## Setup

### Prerequisites

- Node.js 18 or higher
- Firebase CLI installed (`npm install -g firebase-tools`)
- Firebase project initialized

### Installation

```bash
cd functions
npm install
```

### Build

```bash
npm run build
```

### Deploy

```bash
# Deploy all functions
npm run deploy

# Or use Firebase CLI directly
firebase deploy --only functions
```

### Local Testing

```bash
# Start emulators
npm run serve

# This will start the Functions emulator
# You can then create test jobs in the Firestore emulator to trigger the function
```

## Environment

The functions use Firebase Admin SDK which is automatically configured when deployed to Firebase.

## Logs

View function logs:

```bash
npm run logs

# Or specific function
firebase functions:log --only onJobCreated
```

## Troubleshooting

### Invalid Token Errors

The function automatically handles invalid FCM tokens by removing them from user documents. This is normal when users uninstall the app or revoke permissions.

### No Notifications Sent

Check that:
1. Users have `notificationToken` field in their Firestore document
2. Users have `skills` or `category` fields that match job categories
3. Users have `city` or `province` fields that match job locations
4. The job owner is not receiving notifications (they are excluded)

## Development

### File Structure

```
functions/
├── src/
│   ├── index.ts          # Main entry point
│   └── onJobCreated.ts   # Job creation trigger
├── package.json
├── tsconfig.json
└── .eslintrc.js
```

### Adding New Functions

1. Create a new file in `src/`
2. Export the function
3. Import and export it in `src/index.ts`
4. Build and deploy
