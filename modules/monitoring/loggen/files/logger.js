// Tableau contenant les différents types de logs
const logLevels = ['INFO', 'DEBUG', 'WARN', 'ERROR'];

// Fonction pour générer une heure actuelle au format lisible
function getCurrentTimestamp() {
    const now = new Date();
    return now.toISOString();
}

// Fonction pour générer un message de log aléatoire
function generateRandomLog() {
    const level = logLevels[Math.floor(Math.random() * logLevels.length)];
    const timestamp = getCurrentTimestamp();
    const message = `This is a ${level} log message`;
    console.log(`[${timestamp}] [${level}] ${message}`);
}

// Fonction principale pour lancer les logs toutes les 20 secondes
function startLogging() {
    console.log("Log generator started. Generating logs every 20 seconds...");
    setInterval(generateRandomLog, 20000);
}

// Démarrer la génération de logs
startLogging();
