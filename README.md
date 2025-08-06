# gSpy - Advanced Phone Monitoring Solution

A comprehensive phone monitoring and parental control solution with web-based dashboard and mobile applications.

## 🚀 Features

### Core Monitoring Features
- **Keylogger**: Capture every keystroke on target devices
- **Screen Recorder**: Visual monitoring with regular screenshots
- **GPS Location Tracking**: Real-time location monitoring with route history
- **Call Monitoring**: Detailed call logs with timestamps and duration
- **Text Message Monitoring**: SMS and iMessage tracking
- **Call Recorder**: Live call recording with crystal-clear audio

### Social Media Monitoring
- **WhatsApp Monitoring**: Complete message and media tracking
- **Facebook Messenger**: Full conversation monitoring
- **Instagram**: Direct messages and activity tracking
- **Snapchat**: Photo and video monitoring
- **Discord**: Server and direct message tracking
- **Telegram**: Secure messaging monitoring
- **Skype**: Video and voice call monitoring
- **Tinder**: Dating app activity monitoring
- **Google Chat**: Workspace communication tracking
- **Line, Viber, Kik**: Additional messaging platform support

### Advanced Features
- **Live Screen Streaming**: Real-time device screen viewing
- **Remote Location Tracking**: Link-based tracking without physical access
- **Keyword Alerts**: Custom keyword monitoring and notifications
- **Geofencing**: Location-based alerts and safe zones
- **App Viewer**: Installed applications monitoring
- **App Blocker**: Remote application blocking
- **Browser History**: Web browsing activity tracking
- **Bookmarks**: Saved website monitoring
- **Email Monitoring**: Email client activity tracking
- **Calendar Monitoring**: Schedule and event tracking
- **Photo/Video Viewer**: Media file monitoring
- **AI Chatbots Monitoring**: ChatGPT and Gemini activity tracking

### Security & Privacy
- **Hidden Mode**: Undetectable background operation
- **Bank-grade Encryption**: Secure data transmission
- **Real-time Updates**: Data sync every 5 minutes
- **Multi-device Support**: iOS, Android, and desktop compatibility

## 🏗️ Architecture

```
gspy/
├── backend/                 # Node.js/Express API server
├── frontend/               # React web dashboard
├── mobile/                 # React Native mobile apps
├── admin/                  # Admin panel for user management
├── docs/                   # Documentation
└── docker/                 # Docker configuration
```

## 🛠️ Technology Stack

### Backend
- **Node.js** with Express.js
- **MongoDB** for data storage
- **Redis** for caching and sessions
- **Socket.io** for real-time communication
- **JWT** for authentication
- **Multer** for file uploads
- **Crypto** for encryption

### Frontend
- **React.js** with TypeScript
- **Material-UI** for components
- **Redux Toolkit** for state management
- **React Router** for navigation
- **Chart.js** for analytics
- **Leaflet** for maps

### Mobile
- **React Native** with TypeScript
- **Expo** for development
- **Native modules** for device features
- **Push notifications**

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- MongoDB 6+
- Redis 7+
- Docker (optional)

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd gspy
```

2. **Install dependencies**
```bash
# Backend
cd backend && npm install

# Frontend
cd ../frontend && npm install

# Mobile
cd ../mobile && npm install
```

3. **Environment setup**
```bash
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env
```

4. **Start development servers**
```bash
# Backend
cd backend && npm run dev

# Frontend
cd ../frontend && npm start

# Mobile
cd ../mobile && npm start
```

## 📱 Mobile App Installation

### Android
1. Enable Developer Options
2. Enable USB Debugging
3. Install APK from releases
4. Grant necessary permissions

### iOS
1. Install via TestFlight or App Store
2. Trust developer certificate
3. Grant permissions when prompted

## 🔧 Configuration

### Backend Configuration
- Database connection settings
- Redis configuration
- JWT secret keys
- File upload limits
- Monitoring intervals

### Frontend Configuration
- API endpoints
- Feature flags
- Theme customization
- Language settings

## 📊 Dashboard Features

### Control Panel
- Real-time device status
- Activity timeline
- Location tracking map
- Social media feeds
- Call and message logs
- Media gallery
- Settings and preferences

### Analytics
- Usage statistics
- Activity reports
- Location history
- Communication patterns
- App usage analytics

## 🔒 Security Features

- End-to-end encryption
- Secure data transmission
- User authentication
- Role-based access control
- Audit logging
- Data retention policies

## 📋 Legal Compliance

**IMPORTANT**: This software is intended for legal use only. Users must:
- Own the target device or have explicit consent
- Comply with local laws and regulations
- Respect privacy rights
- Use for legitimate purposes only

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Email: support@gspy.com
- Documentation: docs.gspy.com
- Community: community.gspy.com

## ⚠️ Disclaimer

This software is provided "as is" without warranty. Users are responsible for ensuring compliance with applicable laws and regulations. The developers are not liable for any misuse or illegal activities. 