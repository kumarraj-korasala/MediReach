// config/firebase.js — Firebase Admin SDK Initializer
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

let firebaseInitialized = false;

try {
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH 
    ? path.resolve(__dirname, '..', process.env.FIREBASE_SERVICE_ACCOUNT_PATH)
    : path.resolve(__dirname, 'firebase-service-account.json');

  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    firebaseInitialized = true;
    console.log('[FIREBASE] Admin SDK successfully initialized.');
  } else {
    console.log('[FIREBASE] Info: No service account file found. Push notification simulation mode active.');
  }
} catch (err) {
  console.warn('[FIREBASE] Warning: Firebase Admin failed to initialize:', err.message);
}

/**
 * Send high-priority emergency notification via FCM (or simulated log)
 */
async function sendEmergencyAlert(topic, title, body, dataPayload = {}) {
  if (firebaseInitialized) {
    try {
      const message = {
        topic: topic,
        notification: { title, body },
        data: dataPayload,
        android: { priority: 'high' },
      };
      const response = await admin.messaging().send(message);
      console.log(`[FIREBASE] Emergency alert dispatched to ${topic}: ${response}`);
      return { success: true, messageId: response };
    } catch (err) {
      console.error('[FIREBASE] Error sending FCM message:', err.message);
      return { success: false, error: err.message };
    }
  } else {
    console.log(`[FIREBASE SIMULATED] Alert -> [Topic: ${topic}] | Title: "${title}" | Body: "${body}" | Data:`, dataPayload);
    return { success: true, simulated: true };
  }
}

module.exports = { admin, sendEmergencyAlert, isFirebaseActive: () => firebaseInitialized };
