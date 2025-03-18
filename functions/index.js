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
    const smsBody = req.body.Body;
    const fromNumber = req.body.From;

    const parts = smsBody.split(' ');
    if (parts.length < 2 || parts.length > 3) {
        return res.status(400).send('Invalid format. Use: Hole Gross-Score [Points]');
    }
    const holeNumber = parseInt(parts[0]);
    const gross = parseInt(parts[1]);
    const points = parts.length === 3 ? parseInt(parts[2]) : 0; // Points defaults to 0

    if (isNaN(holeNumber) || isNaN(gross) || holeNumber < 1 || holeNumber > 18 || gross < 1 || gross > 15) {
        return res.status(400).send('Hole number must be between 1 and 18, and gross score between 1 and 15.');
    }
    // Validate points if provided
    if (points !== null && (isNaN(points) || points < 0 || points > 10)) {
        return res.status(400).send('Points must be between 0 and 10.');
    }
    try {
        const playerDocRef =
            admin.firestore().collection('games').doc(generateGameId()).collection('players').doc(fromNumber);
        await playerDocRef.set({
            scores: {
                [holeNumber]: {
                    gross: gross,
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                    points: points // Add points to the score object
                }
            },
        }, { merge: true });

        return res.status(200).send('Score updated successfully!');
    } catch (error) {
        logger.error('Error writing to database:', error);
        return res.status(500).send('Error saving score. Please try again later.');
    }
});

exports.addPlayer = onRequest(async (req, res) => {
    const playerName = req.body.playerName;
    const phoneNumber = req.body.phoneNumber;
    const playerCourseHandicapStr = req.body.playerCourseHandicap;

    if (!playerName || !phoneNumber || !playerCourseHandicapStr) {
        return res.status(400).send("Player name, course handicap and phone number are required.");
    }
    const playerCourseHandicap = parseInt(playerCourseHandicapStr);
    if (isNaN(playerCourseHandicap) || playerCourseHandicap < 1 || playerCourseHandicap > 54) {
        return res.status(400).send("The course handicap is outside expected bounds (between 1 and 54).");
    }
    const gameId = generateGameId();
    const playerRef = admin.firestore().collection('games').doc(gameId).collection('players').doc(phoneNumber);

    try {
        const docSnap = await playerRef.get();
        if (!docSnap.exists) {
            // Player doesn't exist, add them
            await playerRef.set({
                name: playerName,
                courseHandicap: playerCourseHandicap,
                scores: {}
            });
        } else {
            // Player exists
            await playerRef.update({
                name: playerName,
                courseHandicap: playerCourseHandicap
            });
        }
        return res.status(200).send('Player data processed successfully!');
    } catch (error) {
        logger.error('Error processing player data:', error);
        return res.status(500).send('Error processing player data. Please try again later.');
    }
});

