import { setGlobalOptions } from "firebase-functions/v2";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

setGlobalOptions({ maxInstances: 10, region: "europe-west1" });

admin.initializeApp();

export const onNewsCreated = onDocumentCreated(
  "events/{eventId}/news/{newsId}",
  async (event) => {
    const eventId = event.params.eventId;
    const data = event.data?.data();

    const titolo = (data?.titolo as string) ?? "Nuovo aggiornamento";

    await admin.messaging().send({
      topic: `event_${eventId}`,
      notification: {
        title: "📰 Nuova news",
        body: titolo,
      },
      data: {
        eventId,
      },
    });

    logger.info("Push inviata", { eventId, titolo });
  }
);
