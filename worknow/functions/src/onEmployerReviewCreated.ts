import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Cloud Function que se activa cuando se crea una nueva reseña de empleador.
 * Actualiza el promedio de calificación del empleador automáticamente.
 */
export const onEmployerReviewCreated = functions.firestore
  .document("users/{employerId}/reviews/{reviewId}")
  .onCreate(async (snapshot, context) => {
    const employerId = context.params.employerId;

    try {
      console.log(`📝 Nueva reseña de empleador para: ${employerId}`);

      // Obtener todas las reseñas del empleador
      const reviewsSnapshot = await admin
        .firestore()
        .collection("users")
        .doc(employerId)
        .collection("reviews")
        .get();

      if (reviewsSnapshot.empty) {
        console.log("❌ No hay reseñas para calcular");
        return null;
      }

      // Calcular promedio
      let totalRating = 0;
      reviewsSnapshot.docs.forEach((doc) => {
        const reviewData = doc.data();
        totalRating += reviewData.rating || 0;
      });

      const count = reviewsSnapshot.docs.length;
      const average = totalRating / count;

      // Actualizar documento del empleador
      await admin.firestore().collection("users").doc(employerId).update({
        employerRatingAverage: average,
        employerRatingCount: count,
      });

      console.log(
        `✅ Rating de empleador actualizado: ${average.toFixed(2)} (${count} reseñas)`
      );

      return null;
    } catch (error) {
      console.error("❌ Error actualizando rating de empleador:", error);
      throw error;
    }
  });

