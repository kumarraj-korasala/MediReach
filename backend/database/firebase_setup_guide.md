# Firebase Admin & Cloud Messaging (FCM) Integration Guide

This guide explains how to connect Firebase Cloud Messaging (FCM) to the MediReach Node.js API Gateway for automated high-priority emergency alerts and appointment reminders.

---

## 1. Firebase Service Account Setup

1. Open the [Firebase Console](https://console.firebase.google.com/).
2. Create or select your project (e.g. `medireach-telehealth`).
3. Navigate to **Project Settings** $\to$ **Service accounts**.
4. Click **Generate new private key**.
5. Save the downloaded JSON file as:
   `backend/node_api/config/firebase-service-account.json`

---

## 2. Environment Variable Configuration

In `backend/node_api/.env`, configure:

```env
FIREBASE_SERVICE_ACCOUNT_PATH=./config/firebase-service-account.json
# Or provide inline credentials
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n..."
```

---

## 3. High-Priority Notification Triggers

The Node.js API automatically invokes FCM when:
- **Emergency Triage**: A vital reading receives `EMERGENCY` or `HIGH` risk score $\to$ Broadcasts instant alert to the duty room device token.
- **Referral Dispatched**: An outbound referral is generated $\to$ Receiving hospital emergency desk receives patient summary.
- **Appointment Reminder**: Scheduled reminder sent to patient 24 hours prior.
