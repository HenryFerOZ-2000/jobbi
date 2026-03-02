import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

interface JobData {
    title: string;
    category: string;
    city: string;
    province?: string;
    country: string;
    ownerId: string;
}

interface UserData {
    uid: string;
    notificationToken?: string;
    skills?: string[];
    category?: string;
    city?: string;
    province?: string;
}

export const onJobCreated = functions.firestore
    .document("jobs/{jobId}")
    .onCreate(async (snapshot, context) => {
        const jobId = context.params.jobId;
        const jobData = snapshot.data() as JobData;

        console.log(`📢 New job created: ${jobId} - ${jobData.title}`);

        try {
            // Extract job information
            const { title, category, city, province, country, ownerId } = jobData;

            // Query users who might be interested
            const usersRef = admin.firestore().collection("users");

            // Build query to find matching users
            // We'll get all users and filter in memory for complex matching
            const usersSnapshot = await usersRef.get();

            const matchingUsers: UserData[] = [];

            usersSnapshot.forEach((userDoc) => {
                const userData = userDoc.data() as UserData;
                const userId = userDoc.id;

                // Skip the job owner
                if (userId === ownerId) {
                    return;
                }

                // Check if user matches by interests/skills
                let matchesByInterest = false;
                if (userData.skills && Array.isArray(userData.skills)) {
                    // Check if any skill matches the job category
                    matchesByInterest = userData.skills.some((skill: string) =>
                        skill.toLowerCase().includes(category.toLowerCase()) ||
                        category.toLowerCase().includes(skill.toLowerCase())
                    );
                }

                // Also check the category field
                if (!matchesByInterest && userData.category) {
                    matchesByInterest =
                        userData.category.toLowerCase() === category.toLowerCase() ||
                        userData.category.toLowerCase().includes(category.toLowerCase()) ||
                        category.toLowerCase().includes(userData.category.toLowerCase());
                }

                // Check if user matches by location
                let matchesByLocation = false;
                if (userData.city && userData.city.toLowerCase() === city.toLowerCase()) {
                    matchesByLocation = true;
                } else if (userData.province && province &&
                    userData.province.toLowerCase() === province.toLowerCase()) {
                    matchesByLocation = true;
                }

                // Add user if they match by interest OR location
                if (matchesByInterest || matchesByLocation) {
                    matchingUsers.push({
                        uid: userId,
                        notificationToken: userData.notificationToken,
                        ...userData,
                    });
                }
            });

            console.log(`✅ Found ${matchingUsers.length} matching users`);

            // Create notifications and send FCM messages
            const promises: Promise<any>[] = [];

            for (const user of matchingUsers) {
                // Create notification document in Firestore
                const notificationRef = admin.firestore()
                    .collection("users")
                    .doc(user.uid)
                    .collection("notifications")
                    .doc();

                const notificationData = {
                    title: `Nuevo trabajo en ${city}`,
                    body: `Hay un nuevo empleo de ${category} que podría interesarte: ${title}`,
                    jobId: jobId,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    read: false,
                    type: "new_job",
                };

                promises.push(notificationRef.set(notificationData));

                // Send FCM push notification if user has a token
                if (user.notificationToken) {
                    const message = {
                        notification: {
                            title: notificationData.title,
                            body: notificationData.body,
                        },
                        data: {
                            jobId: jobId,
                            type: "new_job",
                        },
                        token: user.notificationToken,
                    };

                    promises.push(
                        admin.messaging().send(message)
                            .then(() => {
                                console.log(`✅ Notification sent to user ${user.uid}`);
                            })
                            .catch((error: any) => {
                                console.error(`❌ Error sending notification to ${user.uid}:`, error);
                                // If token is invalid, remove it from user document
                                if (error.code === "messaging/invalid-registration-token" ||
                                    error.code === "messaging/registration-token-not-registered") {
                                    return admin.firestore()
                                        .collection("users")
                                        .doc(user.uid)
                                        .update({ notificationToken: admin.firestore.FieldValue.delete() });
                                }
                            })
                    );
                }
            }

            // Wait for all operations to complete
            await Promise.all(promises);

            console.log(`🎉 Successfully processed notifications for job ${jobId}`);
            return null;
        } catch (error) {
            console.error("❌ Error processing job creation:", error);
            throw error;
        }
    });
