# 💰 F-Buddy - Your Personal Finance & Group Expense Manager

A comprehensive financial management app that combines personal expense tracking with Splitwise-style group expense management. Track your spending, manage budgets, and split bills with friends - all in one beautiful Flutter app!

---

## 🚀 Quick Start

### Backend
```bash
cd backend
npm start
```

### Mobile App
```bash
cd mobile
flutter run
```

> **Note**: Make sure MongoDB is running and configured in your `.env` file before starting the backend.

---

## 📋 Prerequisites

- **Node.js** (v14 or higher)
- **Flutter** (v3.0 or higher)
- **MongoDB** (Local or Atlas)
- **Android/iOS Emulator** or physical device

---

## ⚙️ Setup & Configuration

### 1. Backend Setup

1. Navigate to backend folder:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create `.env` file with:
   ```env
   PORT=5001
   MONGODB_URI=your_mongodb_connection_string
   JWT_SECRET=your_secret_key
   NODE_ENV=development
   ```

4. Start the server:
   ```bash
   npm start
   ```

### 2. Mobile App Setup

1. Navigate to mobile folder:
   ```bash
   cd mobile
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Update API endpoint in `lib/config/constants.dart` if needed

4. Run the app:
   ```bash
   flutter run
   ```

---

## ✨ Features

### 📊 Personal Finance Management

#### **Expense Tracking**
- Add expenses with amount, category, description, and date
- 18+ pre-defined categories (Food, Transport, Health, etc.)
- Swipe-to-delete with confirmation dialog
- Visual hint showing how to delete expenses
- Automatic dashboard refresh after changes

#### **Income Management**
- Track multiple income sources
- Set recurring income (monthly, weekly, one-time)
- Monitor current month's total income

#### **Smart Analytics**
- **Monthly Balance**: Real-time calculation of income vs expenses
- **7-Day Balance Chart**: Visual trend of your spending
- **Category Breakdown**: Pie chart showing expense distribution
- **Latest Expenses**: Quick view of recent transactions

#### **Budget Management**
- Set category-wise budgets
- Real-time budget tracking
- Visual progress indicators
- Overspending alerts

#### **Debt Tracking**
- Record money you owe or others owe you
- Set due dates and get reminders
- Track debt status (pending/paid)

### 👥 Group Expense Management (Splitwise)

#### **Group Creation & Management**
- Create groups with custom names
- Generate unique invite codes
- Join groups using invite codes
- View all your groups in one place

#### **Member Management**
- Add members by email
- Automatic user lookup in database
- Prevent duplicate member additions
- View member balances (owed/lent)
- Transfer group ownership before leaving
- Leave group functionality

#### **Smart Expense Splitting**
- Add group expenses with flexible splits
- **Auto-split**: Equally divide among selected members
- **Custom split**: Set individual amounts per member
- **Payer selection**: Choose who paid the bill
- **Member selection**: Pick who's involved in the split
- **Category tagging**: Organize expenses by type

#### **Automatic Sync with Personal Finance**
- Your share auto-syncs to personal expenses
- Linked to group expense for consistency
- Category mapping (restaurant → food, etc.)
- Monthly balance updates automatically

#### **Settlement System**
- **Simplified settlements**: Minimal number of transactions needed
- **Detailed view**: See all individual debts
- **Click-to-settle**: Tap settlement card to mark as paid
- Automatic balance recalculation
- Shows "All settled up" when balances are zero

#### **Group Statistics**
- Total spent in group
- Your personal share
- Amount you owe vs amount you're owed
- Member count
- Expense breakdown by category

#### **Activity Tracking**
- View recent group expenses
- Settlement suggestions
- Real-time updates across all members

#### **Friends View**
- See all unique friends from all groups
- View balance status with each friend
- Quick access to mutual groups

### 🎨 UI/UX Features

#### **Theme Support**
- Light and Dark mode
- Smooth theme transitions
- Consistent color scheme
- Modern, premium design

#### **Navigation**
- Quick switch between Personal Finance and Splitwise
- Bottom navigation for easy access
- Theme toggle in app bar
- Intuitive user flows

#### **Visual Feedback**
- Confirmation dialogs for critical actions
- Success/error snackbars
- Loading indicators
- Real-time data updates

#### **Responsive Design**
- Adapts to different screen sizes
- Scrollable content for long lists
- Optimized for mobile devices
- Clean, uncluttered interface

---

## 🔐 Security Features

- **JWT Authentication**: Secure token-based auth
- **Password Hashing**: Bcrypt encryption
- **Protected Routes**: Middleware authentication
- **Secure Storage**: Flutter secure storage for tokens
- **User Authorization**: Own-data-only access

---

## 🗄️ Tech Stack

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose
- **Authentication**: JWT (JSON Web Tokens)
- **Validation**: Express Validator

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **HTTP Client**: Dio
- **Secure Storage**: flutter_secure_storage
- **Charts**: fl_chart
- **UI**: Material Design

---

## 📱 App Structure

```
F-Buddy/
├── backend/
│   ├── src/
│   │   ├── controllers/      # Business logic
│   │   ├── models/           # MongoDB schemas
│   │   ├── routes/           # API endpoints
│   │   ├── middleware/       # Auth & validation
│   │   └── server.js         # App entry point
│   └── package.json
│
└── mobile/
    ├── lib/
    │   ├── config/           # Constants & theme
    │   ├── models/           # Data models
    │   ├── providers/        # State management
    │   ├── screens/          # UI screens
    │   ├── services/         # API services
    │   └── main.dart         # App entry point
    └── pubspec.yaml
```

---

## 🔄 How Group-Personal Sync Works

1. **Add Group Expense**: 
   - Your share is automatically added to personal finance
   - Linked with `groupId` and `groupExpenseId`
   - Category is mapped appropriately

2. **Monthly Balance Updates**:
   - Personal finance reflects your actual spending
   - Dashboard charts update in real-time
   - Accurate financial insights

3. **Data Consistency**:
   - All expenses persist in MongoDB
   - Survive app restarts
   - Real-time sync across devices

---

## 🎯 Use Cases

### Personal Finance
- Track daily expenses and income
- Monitor spending patterns
- Stay within budget
- Manage debts and loans
- Analyze financial health

### Group Expenses
- Split restaurant bills
- Share apartment rent
- Manage trip expenses
- Track shared subscriptions
- Settle group debts

---

## 🐛 Known Limitations

- Group expenses cannot be deleted (by design)
- Personal expenses linked to groups stay even after settlement
- Maximum 10 latest expenses shown on dashboard

---

## 🚀 Future Enhancements

- [ ] Recurring expense templates
- [ ] Export data to CSV/PDF
- [ ] Bill reminders and notifications
- [ ] Multiple currency support
- [ ] Receipt scanning with OCR
- [ ] Financial goals and savings tracking

---

## 📄 License

This project is part of a private development effort.

---

## 👨‍💻 Developer Notes

- Backend runs on port **5001** by default
- API base URL: `http://localhost:5001/api`
- MongoDB connection required for backend
- Hot reload enabled in Flutter for rapid development

---

## 🆘 Troubleshooting

### Backend won't start
- Check MongoDB connection string
- Ensure MongoDB is running
- Verify `.env` file exists
- Check port 5001 is not in use

### Flutter build errors
- Run `flutter clean` and `flutter pub get`
- Check Flutter version compatibility
- Ensure all dependencies are installed

### Data not syncing
- Verify backend is running
- Check API endpoint in constants
- Ensure valid JWT token
- Check network connectivity

---

## 📞 Support

For issues, questions, or contributions, please contact the development team.

---

**Built with ❤️ by team Code4Change**
