const {onRequest} = require("firebase-functions/v2/https");
const admin = require('firebase-admin');
const logger = require("firebase-functions/logger");

admin.initializeApp();

function generateGameId() {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0'); // Month is 0-indexed
    const dd = String(today.getDate()).padStart(2, '0');
    return `${yyyy}${mm}${dd}`;
}

exports.scoreUpdate = onRequest(async (req, res) => {
    logger.debug("Try get data from request body. Twilio POSTs data here.", {structuredData: true});
    const smsBody = req.body.Body;
    const fromNumber = req.body.From; // Player's mobile number

    logger.debug("Try Parse the SMS body (e.g., \"1 4\" for hole 1, gross 4)", {structuredData: true});
    const parts = smsBody.split(' ');
    if (parts.length !== 2) {
        return res.status(400).send('Invalid format. Use: Hole Gross-Score');
    }
    const holeNumber = parseInt(parts[0]);
    const gross = parseInt(parts[1]);

    logger.debug("Try validation", {structuredData: true});
    if (isNaN(holeNumber) || isNaN(gross) || holeNumber < 1 || holeNumber > 18 || gross < 1 || gross > 15) {
        return res.status(400).send('Hole number must be between 1 and 18, and gross score between 1 and 15.');
    }
    try {
        const playerDocRef =
            admin.firestore().collection('games').doc(generateGameId()).collection('players').doc(fromNumber);
        await playerDocRef.set({
            scores: {
                [holeNumber]: { gross: gross, timestamp: admin.firestore.FieldValue.serverTimestamp() }
            },
        }, { merge: true }); // Use merge to update existing documents without overwriting
        return res.status(200).send('Score updated successfully!');
    } catch (error) {
        logger.error('Error writing to database:', error);
        return res.status(500).send('Error saving gross. Please try again later.');
    }
});
