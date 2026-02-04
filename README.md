# HealthBuddy 🥗🏃‍♂️

![HealthBuddy Banner](https://img.shields.io/badge/HealthBuddy-AI--Powered%20Wellness-009688?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![AI Powered](https://img.shields.io/badge/AI-Groq%20%7C%20Llama3-purple?style=for-the-badge)

**HealthBuddy** is an intelligent, cross-platform health companion app built with Flutter. It integrates **Google Health Connect** to track your daily activity and uses **AI (powered by Groq)** to provide personalized diet plans, health insights, and motivation.

## ✨ Features

*   **📊 Comprehensive Hygiene Tracking**: Syncs seamlessly with Health Connect to track Steps, Sleep, Heart Rate, and Calories.
*   **🤖 NutriGPT Assistant**: Chat with an AI nutritionist to get personalized meal plans, recipe ideas, and wellness advice.
*   **🥗 Automatic Meal Planning**: Generate structured weekly diet plans based on your preferences.
*   **📈 Visual Analytics**: View beautiful charts and heatmaps of your activity progress.
*   **🔒 Privacy First**: Your health data stays on your device using Health Connect; API keys are secured in your environment.

## 📱 Screenshots

| Home Dashboard | Chat with NutriGPT | Sleep Analysis |
|:---:|:---:|:---:|


## 🛠️ Tech Stack

*   **Frontend**: Flutter (Dart)
*   **State Management**: `setState` & `FutureBuilder` (Simple & Effective)
*   **AI/LLM**: Groq Cloud API (Llama 3.3 70B Versatile)
*   **Health Data**: `health` package (Health Connect / Apple Health)
*   **Charts**: `fl_chart`

## 🚀 Getting Started

### Prerequisites

*   **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
*   **Groq API Key**: Get one from [Groq Cloud](https://console.groq.com/)

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/abhimanyus1997/healthbuddy.git
    cd healthbuddy
    ```

2.  **Setup Environment Variables**
    Create a `.env` file in the root directory and add your API Key:
    ```bash
    GROQ_API_KEY=your_api_key_here
    ```

3.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

4.  **Run the App**
    ```bash
    flutter run
    ```

## 📦 Building for Release

To build an optimized, obfuscated APK for Android:

```bash
flutter build apk --obfuscate --split-debug-info=./build/app/outputs/symbols
```

## 🌐 Web Deployment

This project is configured to deploy to **GitHub Pages** automatically.
Visit the live demo: [abhimanyus1997.github.io/healthbuddy](https://abhimanyus1997.github.io/healthbuddy)

## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
