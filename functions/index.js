const {onRequest} = require("firebase-functions/v2/https");
const admin = require('firebase-admin');
const logger = require("firebase-functions/logger");

admin.initializeApp();
const db = admin.firestore();

exports.helloWorld = onRequest((req, res) => {
  res.send('Hello, world!');
});

exports.listGameIds = onRequest(async (req, res) => {
  try {
    const gamesSnapshot = await db.collection('games').get();
    const gameIds = gamesSnapshot.docs.map(doc => doc.id);
    return gameIds;
  } catch (error) {
    console.error("Error fetching game IDs:", error);
    throw new functions.https.HttpsError('internal', 'Failed to fetch game IDs.');
  }
});

function generateGameId() {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0'); // Month is 0-indexed
    const dd = String(today.getDate()).padStart(2, '0');
    const id = `${yyyy}${mm}${dd}`;
    return id;
}

/*
exports.getWinningPlayer = onRequest(async (req, res) => {
    const gameId = generateGameId();
    const debuggingId = `req-${Date.now()}-${Math.random().toString(36).substring(2,15)}`;
    try {
        const gameRef = db.collection('games').doc(gameId);
        const gameSnapshot = await gameRef.get();

        if (!gameSnapshot.exists) {
            logger.warn(debuggingId, `No game found for game ID: ${gameId}`);
            return res.status(404).send(`No game found for today's date.`);
        }

        const playersSnapshot = await gameRef.collection('players').get();
        let winningPlayer = null;
        let highestPoints = -1;

        for (const playerDoc of playersSnapshot.docs) {
            try {
                const playerData = playerDoc.data();
                let totalPoints = 0;
                const scores = playerData.scores;
                //Loop through each hole to sum up the points
                for (const hole in scores) {
                    const score = scores[hole];
                    if (score && score.points !== undefined) {
                        totalPoints += score.points;
                    } else {
                        logger.warn(
                            debuggingId, `Hole ${hole} does not contain points for player ${playerData.name}`);
                    }
                }
                if (totalPoints > highestPoints) {
                    highestPoints = totalPoints;
                    winningPlayer = {
                        name: playerData.name,
                        phoneNumber: playerDoc.id,
                        totalPoints: totalPoints,
                        scores: scores
                    };
                }
            } catch (playerError) {
                logger.error(debuggingId, `Error processing player ${playerDoc.id}:`, playerError);
            }
        }

        if (winningPlayer === null) {
            logger.warn(debuggingId, `No players found for game ID: ${gameId}`);
            return res.status(404).send("No players found for today's game.");
        }

        logger.info(debuggingId, `Winning player found: ${winningPlayer.name}`);
        return res.status(200).json(winningPlayer);

    } catch (error) {
        logger.error(debuggingId, 'Error retrieving winning player:', error);
        return res.status(500).send('Error retrieving winning player. Please try again later.');
    }
});
*/

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
            db.collection('games').doc(generateGameId()).collection('players').doc(fromNumber);
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
    const playerRef = db.collection('games').doc(gameId).collection('players').doc(phoneNumber);

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

