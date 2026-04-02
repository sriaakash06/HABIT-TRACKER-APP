# Trackify AI: The Next-Gen Habit Tracker 🚀

![Trackify Banner](https://img.shields.io/badge/Flutter-v3.11+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-v3.11+-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-4CAF50?style=for-the-badge)

Trackify AI is a premium, AI-powered habit tracking application designed to help you build better habits and achieve your goals. With a sleek "Neon Sanctuary" design and deep AI integration, Trackify provides personalized coaching and advanced data visualization to keep you on the right path.

---

## 🌟 Key Features

### 🤖 Meet Zara - Your AI Habit Coach
Engage with **Zara**, our built-in AI chatbot powered by Groq. Zara analyzes your habits, provides personalized advice, and motivates you with data-driven insights.
- Dynamic habit context during chats
- AI-driven suggestions for improvement
- Interactive, animated UI

### 🎨 Neon Sanctuary Design System
Experience a professional, editorial-style interface with the **Neon Sanctuary** aesthetic.
- Asymmetrical cards and sophisticated typography
- Dynamic dark and light modes
- Responsive calendar with bi-directional scrolling
- Premium micro-animations throughout the app

### 📊 Advanced Analytics & Insights
Visualizing your progress has never been easier.
- **GitHub-Style Heatmap**: Track history and consistency at a glance.
- **Interactive Charts**: Measure streaks and completion rates with `fl_chart`.
- **Export Data**: Generate professional PDF reports and Excel spreadsheets of your progress.

### 📚 Comprehensive Habit Library
Choose from hundreds of curated habit templates tailored for all age groups and lifestyles.
- Simplified habit creation flow
- Templates for fitness, productivity, mental health, and more

---

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (v3.11+)
- **Backend**: [Firebase](https://firebase.google.com/) (Auth, Cloud Firestore)
- **AI Engine**: [Groq API](https://groq.com/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Storage**: `flutter_dotenv` for secure environment management
- **Visualization**: `fl_chart` for dashboards
- **Reporting**: `pdf` and `excel` for data exports

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (v3.11.1 or higher)
- A Firebase Project
- A Groq API Key

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/sriaakash06/Habit-Tracker-App.git
   cd Habit-Tracker-App
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables:**
   Create a `.env` file in the root directory and add the following keys (see `.env.example` as a guide):
   ```env
   GROQ_API_KEY=your_groq_api_key_here
   GOOGLE_SERVER_CLIENT_ID=your_google_server_client_id_here
   FIREBASE_PROJECT_ID=your_project_id
   # ... add other firebase specific keys
   ```

4. **Setup Firebase:**
   Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are correctly placed in their respective directories (`android/app/` and `ios/Runner/`).

5. **Run the app:**
   ```bash
   flutter run
   ```

---

## 📂 Project Structure

```text
lib/
├── models/         # Data models (Habit, User, etc.)
├── providers/      # State management (ThemeProvider, HabitProvider)
├── screens/        # Main UI screens (HomeScreen, ZaraChatScreen, etc.)
├── widgets/        # Reusable UI components
├── main.dart       # App entry point
└── firebase_options.dart # Firebase configuration
```

---

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 📧 Contact

**Sriaakash** - [@sriaakash](https://github.com/sriaakash)

Project Link: [https://github.com/sriaakash06/Habit-Tracker-App](https://github.com/sriaakash06/Habit-Tracker-App)
