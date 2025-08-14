require('dotenv').config();

const express = require('express');
const fetch = require('node-fetch');
const textToSpeech = require('@google-cloud/text-to-speech');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const app = express();

// Heroku için proxy ayarı
app.set('trust proxy', 1);

// Middleware
app.use(express.json({ limit: '10mb' }));
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
    credentials: true
}));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 dakika
    max: 100,                 // her IP için max 100 istek
    message: { error: 'Too many requests, please try again later' }
});
app.use(limiter);

// API Key kontrolü
const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY;
const DEEPL_API_KEY = process.env.DEEPL_API_KEY;
const GOOGLE_TTS_KEY_PATH = process.env.GOOGLE_TTS_KEY_PATH;

if (!GOOGLE_API_KEY || !DEEPL_API_KEY || !GOOGLE_TTS_KEY_PATH) {
    console.error('Missing required environment variables');
    process.exit(1);
}

// Google TTS Client
let ttsClient;
try {
    ttsClient = new textToSpeech.TextToSpeechClient({
        keyFilename: GOOGLE_TTS_KEY_PATH
    });
} catch (error) {
    console.error('Failed to initialize Google TTS client:', error.message);
    process.exit(1);
}

// Root route – Heroku’da çalıştığını test etmek için
app.get('/', (req, res) => {
    res.send('Voicely Backend is running 🚀');
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Buraya diğer translate ve tts endpoint’leri eklenir
// Örn: /translate/google, /translate/deepl, /tts vs...

// 404 handler – root ve diğer endpoint’lerden sonra gelmeli
app.use('*', (req, res) => {
    res.status(404).json({
        success: false,
        error: 'Endpoint not found'
    });
});

// Server başlat
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Translation server running on port ${PORT}`);
    console.log(`📝 Health check: http://localhost:${PORT}/health`);
    console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
