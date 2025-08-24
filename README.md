# Bloomie - Child Genetic Profiling System

## 🎯 Project Overview

**Bloomie** is a comprehensive child genetic profiling application designed to help parents track their child's development through personalized recommendations based on genetic analysis. The system provides AI-powered insights, developmental tracking, and medical consultation features.

### 📱 **This is primarily a MOBILE application**
- **Primary Platform**: Flutter mobile app (iOS/Android)
- **Web Version**: Available at [https://dlairay.github.io/BrightgenGeneticsSDS/](https://dlairay.github.io/BrightgenGeneticsSDS/) but is simply a **Flutter-to-web conversion** for demo purposes
- **Optimal Experience**: Download and run the mobile app

## 🌟 Core Features

### 1. **Genetic Analysis & Child Profiling**
- Upload genetic reports (JSON/PDF format) to create personalized child profiles
- AI-powered analysis of genetic traits and developmental markers

### 2. **Weekly Development Check-ins**
- Interactive questionnaires tailored to your child's genetic profile
- Personalized recommendations for cognitive & behavioral development
- Progress tracking over time with detailed activity suggestions

### 3. **Dr. Bloom AI Medical Consultation** 🩺
- Chat with AI medical assistant for health concerns
- Image support for symptoms, rashes, or injuries
- Generates structured medical visit logs for actual doctor appointments
- Emergency symptom detection and guidance

### 4. **Immunity & Resilience Dashboard**
- Genetic-based immunity recommendations
- "Provide" and "Avoid" guidance for foods and activities
- Medical visit history tracking

### 5. **Growth & Development Roadmap**
- Age-based nutritional and developmental milestones
- Interactive timeline showing child's genetic developmental journey
- Food recommendations based on genetic markers

## 🏗️ System Architecture

### Backend (Python FastAPI + Google Cloud)
- **API**: FastAPI with comprehensive health, auth, and feature endpoints
- **Database**: Google Cloud Firestore for scalable document storage
- **AI/ML**: Google Vertex AI integration for genetic analysis and recommendations
- **RAG System**: Advanced retrieval-augmented generation for medical knowledge
- **Deployment**: Google Cloud Run for serverless scaling

### Frontend (Flutter)
- **Mobile**: Native iOS/Android app with full feature set
- **Web**: Flutter web conversion for demonstration (limited mobile-optimized UX)
- **UI/UX**: Custom design system with consistent Fredoka font family
- **State Management**: Provider pattern for reactive UI updates

### Key Integrations
- **Google Cloud Services**: Firestore, Vertex AI, Cloud Run, Identity
- **Authentication**: JWT-based secure user management
- **File Processing**: Multi-format genetic report parsing (JSON, PDF)
- **Real-time Features**: Live chat with Dr. Bloom AI assistant

## 🚀 Getting Started

### For Users (Quick Demo)
1. **Web Demo**: Visit [https://dlairay.github.io/BrightgenGeneticsSDS/](https://dlairay.github.io/BrightgenGeneticsSDS/)
2. **Sample Login**: 
   - Email: `ray@mail.com`
   - Password: `Password1`
3. **Try Features**: Upload genetic report, start check-ins, chat with Dr. Bloom

### For Developers (Full Setup)
📋 **Complete deployment instructions available in**: `DEPLOYMENT.md`

#### Quick Start Options:

**Option 1: Automated Setup (Recommended)**
```bash
# Clone and setup
git clone <repository-url>
cd <repository-name>
git checkout submission

# Run automated infrastructure setup
chmod +x setup_infrastructure.sh
./setup_infrastructure.sh
```

**Option 2: Manual Setup**
1. **Backend Setup**:
   ```bash
   cd backend
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   cp .env.example .env  # Fill in your config
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

2. **Frontend Setup**:
   ```bash
   cd bloomie_frontend
   flutter pub get
   flutter run  # For mobile
   flutter run -d web  # For web version
   ```

## 📚 Documentation & Resources

- **📖 Complete Setup Guide**: [`DEPLOYMENT.md`](DEPLOYMENT.md)
- **🛠️ Infrastructure Script**: [`setup_infrastructure.sh`](setup_infrastructure.sh)  
- **⚙️ Environment Template**: [`backend/.env.example`](backend/.env.example)
- **📱 Frontend Details**: [`bloomie_frontend/CLAUDE.md`](bloomie_frontend/CLAUDE.md)
- **🔧 Backend API**: [`backend/CLAUDE.md`](backend/CLAUDE.md)

## 🔧 Development Notes

### Branch Structure
- **`submission`**: Main development branch with latest features (current)
- **`veetwo`**: Backend with RAG functionality 
- **`veethree`**: Frontend UI improvements
- **`master`**: Legacy branch

### Key Technologies
- **Backend**: Python 3.11+, FastAPI, Google Cloud SDK, Vertex AI
- **Frontend**: Flutter 3.8.0+, Dart, Provider state management
- **Database**: Google Cloud Firestore (NoSQL document database)
- **Deployment**: Google Cloud Run (serverless containers)
- **CI/CD**: Manual deployment (GitHub Actions removed for simplicity)

## 🎨 Design Philosophy

**Mobile-First Development**: Every feature is designed for mobile interaction patterns, with web support as a secondary consideration. The genetic profiling system emphasizes:
- **Visual Data Presentation**: Charts, progress tracking, and interactive elements
- **Conversational AI**: Natural chat interface with Dr. Bloom
- **Genetic-Based Personalization**: All recommendations tailored to individual child's genetic markers
- **Parent-Friendly UX**: Simple, intuitive flows for busy parents

## 🔐 Security & Privacy

- **Data Protection**: All genetic data encrypted in transit and at rest
- **Authentication**: JWT-based secure sessions with API key protection
- **Medical Privacy**: Dr. Bloom conversations automatically deleted after medical log generation
- **Access Control**: User data isolated by authentication boundaries

## 📄 License & Usage

This project is designed for educational and demonstration purposes. For production use, ensure compliance with:
- HIPAA regulations for medical data
- GDPR for genetic information privacy  
- Local healthcare software requirements

---

**Questions or Issues?** 
- Check [`DEPLOYMENT.md`](DEPLOYMENT.md) for detailed setup instructions
- Review the automated setup script: [`setup_infrastructure.sh`](setup_infrastructure.sh)
- Try the live demo: [https://dlairay.github.io/BrightgenGeneticsSDS/](https://dlairay.github.io/BrightgenGeneticsSDS/)

**Built with ❤️ using Flutter & Google Cloud**