const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.onNewsCreated = functions
  .region("europe-west1")
  .firestore
  .document("events/{eventId}/news/{newsId}")
  .onCreate(async (snap, context) => {
    const eventId = context.params.eventId;
    const safeEventId = eventId.replace(/[^a-zA-Z0-9_-]/g, "_");

    const news = snap.data() || {};
    const titolo = news.titolo || "Nuovo aggiornamento";

    await admin.messaging().send({
      topic: `event_${safeEventId}`,
      notification: {
        title: "📰 Nuova news",
        body: titolo,
      },
      data: { eventId }, // qui manteniamo l'ID vero
    });

    return null;
  });
