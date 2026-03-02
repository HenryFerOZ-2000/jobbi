import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

// Export Cloud Functions
export { onJobCreated } from "./onJobCreated";
export { onEmployerReviewCreated } from "./onEmployerReviewCreated";
