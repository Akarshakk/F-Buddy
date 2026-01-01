# F Buddy - Student Finance Tracking App

A comprehensive finance tracking application designed specifically for students to manage their pocket money and expenses effectively.

## 📱 Features

### Core Features
- **User Authentication**: Secure JWT-based authentication
- **Income Tracking**: Add monthly pocket money or income from various sources
- **Expense Tracking**: Manually add expenses with category selection
- **Category System**: 14 predefined categories (clothes, drinks, education, food, fuel, fun, health, hotel, personal, pets, restaurants, tips, transport, others)

### Analytics & Insights
- **Pie Chart**: Real-time category-wise expense breakdown
- **7-Day Balance Chart**: Income vs Expense visualization (available after 7 days of entries)
- **Latest Expenses Table**: View the 10 most recent transactions
- **Monthly Summary**: Track income, expenses, and savings rate

## 🏗️ Project Structure

```
F Buddy/
├── backend/                 # Node.js + Express API
│   ├── src/
│   │   ├── config/         # Database configuration
│   │   ├── controllers/    # Route controllers
│   │   ├── middleware/     # Auth & validation middleware
│   │   ├── models/         # MongoDB schemas
│   │   ├── routes/         # API routes
│   │   └── server.js       # Entry point
│   ├── .env                # Environment variables
│   └── package.json
│
└── mobile/                  # Flutter Mobile App
    ├── lib/
    │   ├── config/         # Theme & constants
    │   ├── models/         # Data models
    │   ├── providers/      # State management
    │   ├── screens/        # UI screens
    │   ├── services/       # API service
    │   └── main.dart       # Entry point
    └── pubspec.yaml
```

## 🚀 Getting Started

### Prerequisites
- Node.js (v18+)
- MongoDB (local or Atlas)
- Flutter SDK (3.0+)
- Android Studio / Xcode

### Backend Setup

1. Navigate to backend directory:
```bash
cd "F Buddy/backend"
```

2. Install dependencies:
```bash
npm install
```

3. Configure environment variables in `.env`:
```env
PORT=5000
MONGODB_URI=mongodb://localhost:27017/fbuddy
JWT_SECRET=your_secret_key
JWT_EXPIRE=30d
```

4. Start the server:
```bash
npm run dev
```

### Mobile App Setup

1. Navigate to mobile directory:
```bash
cd "F Buddy/mobile"
```

2. Get Flutter dependencies:
```bash
flutter pub get
```

3. Update API URL in `lib/config/constants.dart`:
```dart
// For Android emulator: 10.0.2.2
// For iOS simulator: localhost
// For physical device: your computer's IP
static const String baseUrl = 'http://localhost:5000/api';
```

4. Run the app:
```bash
flutter run
```

## 📡 API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login user |
| GET | `/api/auth/me` | Get current user |
| PUT | `/api/auth/update` | Update profile |

### Income
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/income` | Add income |
| GET | `/api/income` | Get all incomes |
| GET | `/api/income/current` | Get current month income |
| PUT | `/api/income/:id` | Update income |
| DELETE | `/api/income/:id` | Delete income |

### Expenses
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/expenses` | Add expense |
| GET | `/api/expenses` | Get all expenses |
| GET | `/api/expenses/latest` | Get latest 10 expenses |
| GET | `/api/expenses/:id` | Get single expense |
| PUT | `/api/expenses/:id` | Update expense |
| DELETE | `/api/expenses/:id` | Delete expense |

### Analytics
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/analytics/category` | Category breakdown |
| GET | `/api/analytics/summary` | Weekly/monthly summary |
| GET | `/api/analytics/balance-chart` | 7-day balance chart |
| GET | `/api/analytics/dashboard` | Dashboard data |

### Categories
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/categories` | Get all categories |

## 📊 Database Schema

### User
```javascript
{
  name: String,
  email: String (unique),
  password: String (hashed),
  monthlyBudget: Number,
  createdAt: Date
}
```

### Income
```javascript
{
  user: ObjectId,
  amount: Number,
  description: String,
  source: Enum ['pocket_money', 'salary', 'freelance', 'gift', 'scholarship', 'other'],
  month: Number,
  year: Number,
  date: Date
}
```

### Expense
```javascript
{
  user: ObjectId,
  amount: Number,
  category: Enum ['clothes', 'drinks', 'education', 'food', 'fuel', 'fun', 'health', 'hotel', 'personal', 'pets', 'restaurants', 'tips', 'transport', 'others'],
  description: String,
  date: Date
}
```

## 🎨 Categories

| Category | Emoji | Color |
|----------|-------|-------|
| Clothes | 👕 | Purple |
| Drinks | 🍺 | Orange |
| Education | 📚 | Blue |
| Food | 🍔 | Green |
| Fuel | ⛽ | Brown |
| Fun | 🎮 | Pink |
| Health | 💊 | Cyan |
| Hotel | 🏨 | Indigo |
| Personal | 👤 | Grey |
| Pets | 🐾 | Light Green |
| Restaurants | 🍽️ | Deep Orange |
| Tips | 💰 | Amber |
| Transport | 🚗 | Teal |
| Others | 📦 | Grey |

## 🔒 Security

- Passwords are hashed using bcrypt
- JWT tokens for authentication
- Protected API endpoints
- Secure token storage in mobile app

## 👥 Team

F Buddy Team - Hackrypt Hackathon 2024

## 📄 License

MIT License
