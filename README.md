# Zero-Hunger-App
🌍 Zero Hunger - Leftover Food Share App  Zero Hunger is a mobile application developed to tackle United Nations SDG 2 (Zero Hunger). It serves as a bridge between restaurants/households with surplus food and local shelters or individuals in need.  Project for: PLP Academy (Power Learn Project) - 2️⃣ Zero Hunger

Key Features

🗺️ Live Rescue Map: View available food donations nearby using OpenStreetMap integration.

🔄 Dual Roles: Switch seamlessly between Donor Mode (post food) and Receiver Mode (claim food).

📦 Easy Donations: Quickly list items with a photo, description, and expiry time.

🤝 Request System: Claim food items and get pickup instructions.

💳 M-Pesa Support: (Simulation) Integrated donation channel for supporting the platform.

🛠️ Tech Stack

Framework: Flutter (Dart)

State Management: Riverpod (ConsumerWidget, StateNotifier)

Maps: flutter_map & latlong2 (OpenStreetMap)

Architecture: Clean Architecture (Domain, Data, Presentation layers)

Utilities: intl (Date formatting), uuid (Unique IDs)

📂 Project Structure

The project follows a clean architecture approach:

lib/
├── main.dart  # Contains the core logic, split into:



⚡ Getting Started

Follow these steps to run the project locally:

Clone the repository:

git clone [https://github.com/YOUR-USERNAME/zero_hunger_app.git](https://github.com/YOUR-USERNAME/zero_hunger_app.git)


Navigate to the project folder:

cd zero_hunger_app


Install dependencies:

flutter pub get


Run the app:

flutter run


🤝 Contributing

Contributions are welcome! Please fork the repository and create a pull request for any feature or bug fix.

📄 License

This project is open-source and available under the MIT License.
