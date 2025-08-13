# Production Setup Guide

## 🚀 Backend Hosting Options

### Option 1: Heroku (Recommended - Free Tier)
```bash
# Install Heroku CLI
npm install -g heroku

# Login and create app
heroku login
heroku create voicely-translation-api

# Set environment variables
heroku config:set GOOGLE_API_KEY="your-google-api-key"
heroku config:set DEEPL_API_KEY="your-deepl-api-key"
heroku config:set NODE_ENV="production"

# Deploy
git add .
git commit -m "Deploy to production"
git push heroku main
```

### Option 2: Railway (Modern Alternative)
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login and deploy
railway login
railway new
railway up
```

### Option 3: Vercel (Serverless)
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel --prod
```

## 📱 Flutter App Production Config

### 1. Environment-based URLs
```dart
class ApiConfig {
  static const bool _isProduction = bool.fromEnvironment('dart.vm.product');
  
  static String get baseUrl {
    if (_isProduction) {
      return 'https://voicely-translation-api.herokuapp.com';
    } else {
      return 'http://192.168.1.8:3000'; // Local development
    }
  }
}
```

### 2. Backend URL Update
```dart
class BackendTranslationService {
  static String get _baseUrl => ApiConfig.baseUrl;
  // ... rest of the code
}
```

## 🔒 Security Considerations

### 1. API Key Protection
- ✅ DeepL and Google keys are server-side only
- ✅ No API keys exposed in mobile app
- ✅ Rate limiting enabled

### 2. CORS Configuration
```javascript
app.use(cors({
    origin: [
        'https://voicely.app',
        'http://localhost:3000'
    ],
    credentials: true
}));
```

### 3. Environment Variables (.env)
```env
# Production Environment Variables
GOOGLE_API_KEY=your-production-google-key
DEEPL_API_KEY=your-production-deepl-key
GOOGLE_TTS_KEY_PATH=/app/credentials/google-service-account.json
NODE_ENV=production
ALLOWED_ORIGINS=https://voicely.app,https://www.voicely.app
```

## 📊 API Usage Limits

### DeepL Free API
- ✅ 500,000 characters/month
- ✅ No request rate limit
- ✅ High quality translations

### Google Translate API
- ⚠️ Pay-per-use after free tier
- ✅ $20/month free credit
- ✅ $20 per 1M characters

### Google Cloud TTS
- ✅ 1M characters/month free
- ✅ $4.00 per 1M characters after

## 💰 Cost Estimation

### Monthly Usage (1000 active users):
- **DeepL**: Free (under 500k chars)
- **Google Translate**: ~$50-100/month
- **Google TTS**: ~$20-40/month
- **Hosting**: $0-25/month
- **Total**: ~$70-165/month

## 🚦 Go-Live Checklist

### Backend:
- [ ] Deploy to Heroku/Railway/Vercel
- [ ] Set production environment variables
- [ ] Configure CORS for mobile app
- [ ] Test all endpoints
- [ ] Monitor logs and errors

### Mobile App:
- [ ] Update API URLs for production
- [ ] Test on real devices
- [ ] Handle network errors gracefully
- [ ] Add loading states
- [ ] Test offline functionality

### Monitoring:
- [ ] Set up error tracking (Sentry)
- [ ] Monitor API usage
- [ ] Set up alerts for failures
- [ ] Track user metrics