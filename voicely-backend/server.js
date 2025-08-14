
require('dotenv').config();

const express = require('express');
const fetch = require('node-fetch');
const textToSpeech =
require('@google-cloud/text-to-speech');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const multer = require('multer');
const path = require('path');
const fs = require('fs-extra');
const { v4: uuidv4 } = require('uuid');
const pdfParse = require('pdf-parse');
const mammoth = require('mammoth');

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

// === FILE UPLOAD & PROCESSING ENDPOINTS === //

// Multer configuration for file uploads
const storage = multer.diskStorage({
    destination: async (req, file, cb) => {
        const uploadDir = path.join(__dirname, 'uploads');
        await fs.ensureDir(uploadDir);
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const uniqueId = uuidv4();
        const ext = path.extname(file.originalname);
        cb(null, `${uniqueId}${ext}`);
    }
});

const upload = multer({
    storage: storage,
    limits: {
        fileSize: 50 * 1024 * 1024, // 50MB max
    },
    fileFilter: (req, file, cb) => {
        const allowedTypes = /\.(mp3|wav|m4a|aac|pdf|docx|doc|txt)$/i;
        if (allowedTypes.test(file.originalname)) {
            cb(null, true);
        } else {
            cb(new Error('Invalid file type. Only audio (MP3, WAV, M4A, AAC) and document (PDF, DOCX, DOC, TXT) files are allowed.'));
        }
    }
});

// File upload and processing endpoint
app.post('/upload-process', upload.single('file'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        const { targetLanguage, outputFormat } = req.body;
        const fileId = uuidv4();
        const filePath = req.file.path;
        const fileName = req.file.originalname;
        const fileExt = path.extname(fileName).toLowerCase();

        console.log(`Processing file: ${fileName} (${fileExt})`);

        let originalText = '';
        let isAudioFile = ['.mp3', '.wav', '.m4a', '.aac'].includes(fileExt);

        // Extract text from file
        if (isAudioFile) {
            // Audio processing with mock transcription for demo
            originalText = await processAudioFile(filePath);
        } else {
            // Document processing
            originalText = await processDocumentFile(filePath, fileExt);
        }

        // Translate the text
        let translatedText = '';
        if (originalText.trim()) {
            translatedText = await translateText(originalText, targetLanguage);
        }

        // Create result file
        const resultFilePath = await createResultFile({
            originalText,
            translatedText,
            fileName,
            targetLanguage,
            outputFormat,
            fileId,
            isAudioFile
        });

        // Clean up uploaded file
        await fs.remove(filePath);

        // Return result
        res.json({
            id: fileId,
            fileName: fileName,
            fileType: isAudioFile ? 'audio' : 'document',
            originalText: originalText.substring(0, 500) + (originalText.length > 500 ? '...' : ''),
            translatedText: translatedText.substring(0, 500) + (translatedText.length > 500 ? '...' : ''),
            sourceLanguage: 'auto',
            targetLanguage,
            outputFormat,
            downloadUrl: `${req.protocol}://${req.get('host')}/download/${fileId}.${outputFormat}`,
            timestamp: new Date().toISOString(),
            isProcessed: true,
        });

    } catch (error) {
        console.error('Upload processing error:', error);
        
        // Clean up file if exists
        if (req.file && req.file.path) {
            try {
                await fs.remove(req.file.path);
            } catch (cleanupError) {
                console.error('Cleanup error:', cleanupError);
            }
        }

        res.status(500).json({
            error: 'File processing failed',
            details: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

// Download processed file endpoint
app.get('/download/:filename', async (req, res) => {
    try {
        const filename = req.params.filename;
        const filePath = path.join(__dirname, 'results', filename);

        if (!await fs.pathExists(filePath)) {
            return res.status(404).json({ error: 'File not found' });
        }

        const stat = await fs.stat(filePath);
        const ext = path.extname(filename).toLowerCase();

        // Set appropriate content type
        const contentTypes = {
            '.txt': 'text/plain',
            '.pdf': 'application/pdf',
            '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            '.srt': 'application/x-subrip',
            '.vtt': 'text/vtt'
        };

        res.setHeader('Content-Type', contentTypes[ext] || 'application/octet-stream');
        res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
        res.setHeader('Content-Length', stat.size);

        const fileStream = fs.createReadStream(filePath);
        fileStream.pipe(res);

    } catch (error) {
        console.error('Download error:', error);
        res.status(500).json({ error: 'Download failed' });
    }
});

// Upload history endpoint
app.get('/upload-history', async (req, res) => {
    try {
        // In a real app, this would query a database
        // For demo, return mock data
        const mockHistory = [
            {
                id: '1',
                fileName: 'sample_audio.mp3',
                fileType: 'audio',
                originalText: 'This is a sample transcription from an audio file...',
                translatedText: 'Bu ses dosyasından örnek bir transkripsiyon...',
                sourceLanguage: 'en',
                targetLanguage: 'tr',
                outputFormat: 'txt',
                downloadUrl: `${req.protocol}://${req.get('host')}/download/1.txt`,
                timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
                isProcessed: true,
            }
        ];

        res.json(mockHistory);
    } catch (error) {
        console.error('History error:', error);
        res.status(500).json({ error: 'Failed to load history' });
    }
});

// Delete upload history item
app.delete('/upload-history/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        // In a real app, delete from database and clean up files
        console.log(`Deleting upload history item: ${id}`);
        
        res.json({ success: true });
    } catch (error) {
        console.error('Delete error:', error);
        res.status(500).json({ error: 'Delete failed' });
    }
});

// === HELPER FUNCTIONS === //

// Process audio file (mock implementation - would use Whisper/AssemblyAI in production)
async function processAudioFile(filePath) {
    try {
        // Mock transcription - replace with actual Whisper/AssemblyAI integration
        console.log(`Mock transcribing audio file: ${filePath}`);
        
        // Simulate processing time
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        return `This is a mock transcription of the uploaded audio file. In a production environment, this would be transcribed using OpenAI Whisper or AssemblyAI. The transcription would contain the actual spoken content from the audio file with proper punctuation and formatting. This demo text shows how the transcription would appear in the final result.`;
    } catch (error) {
        console.error('Audio processing error:', error);
        throw new Error('Audio transcription failed');
    }
}

// Process document file
async function processDocumentFile(filePath, fileExt) {
    try {
        let text = '';
        
        switch (fileExt) {
            case '.txt':
                text = await fs.readFile(filePath, 'utf-8');
                break;
                
            case '.pdf':
                try {
                    const dataBuffer = await fs.readFile(filePath);
                    const data = await pdfParse(dataBuffer);
                    text = data.text;
                } catch (pdfError) {
                    // Fallback for complex PDFs
                    text = 'PDF processing failed. This is a mock text extraction. In production, this would contain the actual text content from the PDF document.';
                }
                break;
                
            case '.docx':
            case '.doc':
                try {
                    const result = await mammoth.extractRawText({ path: filePath });
                    text = result.value;
                } catch (docError) {
                    text = 'Document processing failed. This is a mock text extraction. In production, this would contain the actual text content from the Word document.';
                }
                break;
                
            default:
                throw new Error(`Unsupported file type: ${fileExt}`);
        }
        
        if (!text.trim()) {
            text = 'No text content could be extracted from the document. This might be due to the document being image-based or encrypted.';
        }
        
        return text.trim();
    } catch (error) {
        console.error('Document processing error:', error);
        throw new Error('Document processing failed');
    }
}

// Translate text using existing translation endpoint
async function translateText(text, targetLanguage) {
    try {
        // Use internal translation API
        const response = await fetch('http://localhost:' + (process.env.PORT || 3000) + '/translate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                text: text,
                target: targetLanguage,
                source: 'auto'
            })
        });
        
        if (!response.ok) {
            throw new Error('Translation API failed');
        }
        
        const data = await response.json();
        return data.translatedText || text;
    } catch (error) {
        console.error('Translation error:', error);
        // Return mock translation for demo
        return getMockTranslation(text, targetLanguage);
    }
}

// Create result file in requested format
async function createResultFile({ originalText, translatedText, fileName, targetLanguage, outputFormat, fileId, isAudioFile }) {
    try {
        const resultsDir = path.join(__dirname, 'results');
        await fs.ensureDir(resultsDir);
        
        const resultFileName = `${fileId}.${outputFormat}`;
        const resultFilePath = path.join(resultsDir, resultFileName);
        
        let content = '';
        
        switch (outputFormat) {
            case 'txt':
                content = createTxtFormat(originalText, translatedText, fileName);
                await fs.writeFile(resultFilePath, content, 'utf-8');
                break;
                
            case 'srt':
                if (isAudioFile) {
                    content = createSrtFormat(originalText, translatedText);
                    await fs.writeFile(resultFilePath, content, 'utf-8');
                } else {
                    throw new Error('SRT format only available for audio files');
                }
                break;
                
            case 'vtt':
                if (isAudioFile) {
                    content = createVttFormat(originalText, translatedText);
                    await fs.writeFile(resultFilePath, content, 'utf-8');
                } else {
                    throw new Error('VTT format only available for audio files');
                }
                break;
                
            case 'pdf':
                // For demo, create a simple text file and rename it
                // In production, you'd use a PDF generation library like PDFKit
                content = createTxtFormat(originalText, translatedText, fileName);
                await fs.writeFile(resultFilePath, content, 'utf-8');
                break;
                
            case 'docx':
                // For demo, create a simple text file and rename it
                // In production, you'd use a library like docx or officegen
                content = createTxtFormat(originalText, translatedText, fileName);
                await fs.writeFile(resultFilePath, content, 'utf-8');
                break;
                
            default:
                throw new Error(`Unsupported output format: ${outputFormat}`);
        }
        
        return resultFilePath;
    } catch (error) {
        console.error('Result file creation error:', error);
        throw new Error('Failed to create result file');
    }
}

// Create TXT format content
function createTxtFormat(originalText, translatedText, fileName) {
    return `VOICELY TRANSLATION RESULT
=====================================

File: ${fileName}
Date: ${new Date().toLocaleString()}

ORIGINAL TEXT
=====================================
${originalText}

TRANSLATION
=====================================
${translatedText}

Generated by Voicely - Voice Translation App`;
}

// Create SRT subtitle format
function createSrtFormat(originalText, translatedText) {
    // For demo, create simple subtitle blocks
    const sentences = originalText.split(/[.!?]+/).filter(s => s.trim());
    const translatedSentences = translatedText.split(/[.!?]+/).filter(s => s.trim());
    
    let srt = '';
    let counter = 1;
    
    for (let i = 0; i < Math.max(sentences.length, translatedSentences.length); i++) {
        const startTime = i * 4; // 4 seconds per subtitle
        const endTime = (i + 1) * 4;
        
        const startTimeFormatted = formatSrtTime(startTime);
        const endTimeFormatted = formatSrtTime(endTime);
        
        const originalSentence = sentences[i] || '';
        const translatedSentence = translatedSentences[i] || '';
        
        if (originalSentence.trim()) {
            srt += `${counter}\n`;
            srt += `${startTimeFormatted} --> ${endTimeFormatted}\n`;
            srt += `${originalSentence.trim()}\n`;
            srt += `${translatedSentence.trim()}\n\n`;
            counter++;
        }
    }
    
    return srt;
}

// Create VTT subtitle format
function createVttFormat(originalText, translatedText) {
    const srtContent = createSrtFormat(originalText, translatedText);
    return 'WEBVTT\n\n' + srtContent.replace(/(\d+)\n/g, ''); // Remove numbering for VTT
}

// Format time for SRT (HH:MM:SS,mmm)
function formatSrtTime(seconds) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    const milliseconds = Math.floor((seconds % 1) * 1000);
    
    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')},${milliseconds.toString().padStart(3, '0')}`;
}

// Get mock translation for demo
function getMockTranslation(text, targetLang) {
    const mockTranslations = {
        'tr': 'Bu, yüklenen dosyadan çıkarılan metnin Türkçe çevirisidir. Gerçek bir uygulamada, bu metin Google Translate veya DeepL API\'si kullanılarak çevrilir.',
        'es': 'Esta es la traducción al español del texto extraído del archivo subido. En una aplicación real, este texto se traduciría usando Google Translate o la API de DeepL.',
        'fr': 'Ceci est la traduction française du texte extrait du fichier téléchargé. Dans une vraie application, ce texte serait traduit en utilisant Google Translate ou l\'API DeepL.',
        'de': 'Dies ist die deutsche Übersetzung des aus der hochgeladenen Datei extrahierten Textes. In einer echten Anwendung würde dieser Text mit Google Translate oder der DeepL-API übersetzt.',
        'en': 'This is the English translation of the text extracted from the uploaded file. In a real application, this text would be translated using Google Translate or DeepL API.'
    };
    
    return mockTranslations[targetLang] || mockTranslations['en'];
}

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