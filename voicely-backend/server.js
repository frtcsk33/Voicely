
require('dotenv').config();

const express = require('express');
const fetch = require('node-fetch');
const textToSpeech =
require('@google-cloud/text-to-speech');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const app = express();

// Middleware
app.use(express.json({ limit: '10mb' }));
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') ||        
['http://localhost:3000'],
    credentials: true
}));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 dakika
    max: 100,                 // her IP için max 100 istek
    message: { error: 'Too many requests, please try again later' }
});


app.use(limiter);

// API Key'ler - Validation
const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY;
const DEEPL_API_KEY = process.env.DEEPL_API_KEY;
const GOOGLE_TTS_KEY_PATH =
process.env.GOOGLE_TTS_KEY_PATH;

if (!GOOGLE_API_KEY || !DEEPL_API_KEY ||
!GOOGLE_TTS_KEY_PATH) {
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

// Input validation middleware
const validateTranslateInput = (req, res, next) => {
    const { text, target } = req.body;

    if (!text || typeof text !== 'string') {
        return res.status(400).json({ error: 'Text is required and must be a string' });
    }

    if (!target || typeof target !== 'string') {
        return res.status(400).json({ error: 'Target language is required and must be a string' });
    }

    if (text.length > 5000) {
        return res.status(400).json({ error: 'Text too long (max 5000 characters)' });
    }

    next();
};

const validateTTSInput = (req, res, next) => {
    const { text, languageCode, voiceName } = req.body;       

    if (!text || typeof text !== 'string') {
        return res.status(400).json({ error: 'Text is required and must be a string' });
    }

    if (text.length > 5000) {
        return res.status(400).json({ error: 'Text too long for TTS (max 5000 characters)' });
    }

    next();
};

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new
Date().toISOString() });
});

// Google Translate Endpoint
app.post('/translate/google', validateTranslateInput,
async (req, res) => {
    const { text, target, source } = req.body;

    try {
        const requestBody = { q: text, target: target };      
        if (source) requestBody.source = source;

        const response = await fetch(
            `https://translation.googleapis.com/language/     
translate/v2?key=${GOOGLE_API_KEY}`,
            {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',       
                    'User-Agent': 'VoicelyApp/1.0'
                },
                body: JSON.stringify(requestBody),
                timeout: 10000 // 10 second timeout
            }
        );

        if (!response.ok) {
            throw new Error(`Google Translate API error:      
${response.status} ${response.statusText}`);
        }

        const data = await response.json();

        // Return standardized response
        res.json({
            success: true,
            translatedText:
data.data?.translations?.[0]?.translatedText || '',
            sourceLanguage:
data.data?.translations?.[0]?.detectedSourceLanguage ||       
source,
            provider: 'google'
        });

    } catch (err) {
        console.error('Google Translate error:',
err.message);
        res.status(500).json({
            success: false,
            error: 'Translation failed',
            details: process.env.NODE_ENV ===
'development' ? err.message : undefined
        });
    }
});

// DeepL Translate Endpoint
app.post('/translate/deepl', validateTranslateInput,
async (req, res) => {
    const { text, target, source } = req.body;

    try {
        const formData = new URLSearchParams({
            auth_key: DEEPL_API_KEY,
            text: text,
            target_lang: target.toUpperCase()
        });

        if (source) {
            formData.append('source_lang',
source.toUpperCase());
        }

        const response = await
fetch('https://api-free.deepl.com/v2/translate', {
            method: 'POST',
            headers: {
                'Content-Type':
'application/x-www-form-urlencoded',
                'User-Agent': 'VoicelyApp/1.0'
            },
            body: formData,
            timeout: 10000 // 10 second timeout
        });

        if (!response.ok) {
            throw new Error(`DeepL API error:
${response.status} ${response.statusText}`);
        }

        const data = await response.json();

        // Return standardized response
        res.json({
            success: true,
            translatedText: data.translations?.[0]?.text      
|| '',
            sourceLanguage:
data.translations?.[0]?.detected_source_language ||
source,
            provider: 'deepl'
        });

    } catch (err) {
        console.error('DeepL Translate error:',
err.message);
        res.status(500).json({
            success: false,
            error: 'Translation failed',
            details: process.env.NODE_ENV ===
'development' ? err.message : undefined
        });
    }
});

// Unified translate endpoint (tries DeepL first, then Google)
app.post('/translate', validateTranslateInput, async (req, res) => {
    const { text, target, source, provider } = req.body;      

    // If specific provider requested
    if (provider === 'google') {
        return req.app._router.handle({ ...req, url:
'/translate/google' }, res);
    }
    if (provider === 'deepl') {
        return req.app._router.handle({ ...req, url:
'/translate/deepl' }, res);
    }

    // Try DeepL first, fallback to Google
    try {
        const deeplResponse = await fetch(`${req.protocol     
}://${req.get('host')}/translate/deepl`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json'     
 },
            body: JSON.stringify({ text, target, source       
})
        });

        if (deeplResponse.ok) {
            const data = await deeplResponse.json();
            if (data.success) {
                return res.json(data);
            }
        }
    } catch (error) {
        console.log('DeepL failed, trying Google:',
error.message);
    }

    // Fallback to Google
    try {
        const googleResponse = await fetch(`${req.protocol}://${req.get('host')}/translate/google`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json'     
 },
            body: JSON.stringify({ text, target, source       
})
        });

        const data = await googleResponse.json();
        return res.json(data);

    } catch (error) {
        console.error('Both translation services failed:', error.message);
        res.status(500).json({
            success: false,
            error: 'All translation services are currently unavailable'
        });
    }
});

// Text-to-Speech Endpoint (Base64)
app.post('/tts', validateTTSInput, async (req, res) => {      
    const {
        text,
        languageCode = 'en-US',
        voiceName,
        audioEncoding = 'MP3',
        speakingRate = 1.0,
        pitch = 0.0
    } = req.body;

    // Auto-select voice if not provided
    const selectedVoice = voiceName ||
getDefaultVoice(languageCode);

    const request = {
        input: { text },
        voice: {
            languageCode,
            name: selectedVoice
        },
        audioConfig: {
            audioEncoding,
            speakingRate: Math.max(0.25, Math.min(4.0,        
speakingRate)),
            pitch: Math.max(-20.0, Math.min(20.0, pitch))     
        },
    };

    try {
        const [response] = await
ttsClient.synthesizeSpeech(request);

        if (!response.audioContent) {
            throw new Error('No audio content received from Google TTS');
        }

        // Base64 olarak gönder
        const audioBase64 =
response.audioContent.toString('base64');

        res.json({
            success: true,
            audioBase64,
            audioEncoding,
            languageCode,
            voiceName: selectedVoice
        });

    } catch (err) {
        console.error('TTS error:', err.message);
        res.status(500).json({
            success: false,
            error: 'Text-to-speech failed',
            details: process.env.NODE_ENV ===
'development' ? err.message : undefined
        });
    }
});

// Get available voices endpoint
app.get('/tts/voices', async (req, res) => {
    try {
        const [result] = await ttsClient.listVoices({});      
        const voices = result.voices || [];

        // Group by language
        const voicesByLanguage = voices.reduce((acc,
voice) => {
            voice.languageCodes.forEach(langCode => {
                if (!acc[langCode]) acc[langCode] = [];       
                acc[langCode].push({
                    name: voice.name,
                    gender: voice.ssmlGender,
                    naturalSampleRateHertz:
voice.naturalSampleRateHertz
                });
            });
            return acc;
        }, {});

        res.json({
            success: true,
            voices: voicesByLanguage
        });

    } catch (err) {
        console.error('List voices error:', err.message);     
        res.status(500).json({
            success: false,
            error: 'Failed to fetch available voices'
        });
    }
});

// Helper function to get default voice for language
function getDefaultVoice(languageCode) {
    const defaultVoices = {
        'en-US': 'en-US-Wavenet-D',
        'tr-TR': 'tr-TR-Wavenet-A',
        'es-ES': 'es-ES-Wavenet-A',
        'fr-FR': 'fr-FR-Wavenet-A',
        'de-DE': 'de-DE-Wavenet-A',
        'it-IT': 'it-IT-Wavenet-A',
        'pt-PT': 'pt-PT-Wavenet-A',
        'ru-RU': 'ru-RU-Wavenet-A',
        'ja-JP': 'ja-JP-Wavenet-A',
        'ko-KR': 'ko-KR-Wavenet-A',
        'zh-CN': 'zh-CN-Wavenet-A'
    };

    return defaultVoices[languageCode] ||
`${languageCode}-Wavenet-A`;
}

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({
        success: false,
        error: 'Internal server error'
    });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({
        success: false,
        error: 'Endpoint not found'
    });
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('SIGINT received, shutting down gracefully');
    process.exit(0);
});


app.set('trust proxy', 1); // Heroku için gerekli

// rate limit middleware tanımı buraya gelir

app.get('/', (req, res) => {
    res.send('Voicely Backend is running 🚀');
  });
  

// Server Başlat
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Translation server running on port ${PORT}`);
    console.log(`📝 Health check: http://localhost:${PORT}/health`);
    console.log(`📱 Mobile access: http://192.168.1.8:${PORT}/health`);
    console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;