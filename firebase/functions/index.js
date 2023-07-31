/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
// const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
const {onDocumentUpdated} = require("firebase-functions/v2/firestore");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

exports.newMessageNotification = onDocumentUpdated("chats/{chatId}",
    (event) => {
      logger.log("starting new message");
      // check "lastestSender" field not empty string
      if (event.data.after.data().latestSender != "") {
        // find uid of member who is not the sender from "members" field
        logger.log("latestSender not empty");
        const members = event.data.after.data().members;
        const latestSender = event.data.after.data().latestSender;
        logger.log("members: " + members);
        const receiver = members.filter((member) => member != latestSender)[0];
        logger.log("receiver: " + receiver);
        // get receiver's token from "users" collection
        const receiverRef = admin.firestore().collection("users").doc(receiver);
        receiverRef.get().then((doc) => {
          const receiverToken = doc.data().token;
          logger.log("receiverToken: " + receiverToken);
          // send notification to receiver
          const payload = {
            token: receiverToken,
            notification: {
              title: "One Time Pad 🔒",
              body: "New Encrypted Message",
            },
          };
          admin.messaging().send(payload).then((response) => {
            console.log("Successfully sent message:", response);
            return {success: true};
          }).catch((error) => {
            return {error: error.code};
          });
        }).catch((error) => {
          console.log("Error getting document:", error);
        });
      }
    });
