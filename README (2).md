# 👾 Impostor Cards

A real-time multiplayer social deduction card game built with Flutter and Supabase.

## 📱 About

Impostor Cards is a mobile party game where players are secretly assigned roles — **Crewmates** who know a secret word, and **Impostors** who don't. Players give clues, discuss, and vote to find the Impostor before time runs out!

## 🎮 How to Play

1. **Host** creates a room and selects a topic category
2. Other players **join** using the 6-digit room code
3. Each player privately **reveals their card** on their own phone
4. **Crewmates** see the secret word — **Impostors** don't!
5. Everyone **gives clues** about the word without saying it directly
6. Players **vote** for who they think is the Impostor
7. The player with the most votes is **eliminated**
8. **Crewmates win** if they eliminate the Impostor — **Impostor wins** if they survive!

## ✨ Features

- 🏠 Create and join rooms with 6-digit codes
- 🎯 10+ topic categories (Cricket, Movies, Food, Animals, etc.)
- 🔒 Private card reveal — only you see your role
- ⏱️ 60-second voting timer
- 🗳️ Real-time team voting system
- 🏆 Win/lose result screen
- 🔄 Play again functionality
- 📱 Works on any Android device

## 🛠️ Tech Stack

| Technology | Usage |
|-----------|-------|
| Flutter | Mobile app framework |
| Dart | Programming language |
| Supabase | Backend & real-time database |
| PostgreSQL | Database (via Supabase) |

## 📂 Project Structure

```
lib/
├── main.dart                    # App entry point + Supabase init
├── models/
│   └── game_model.dart          # Game data models
└── screens/
    ├── home_screen.dart         # Home page
    ├── create_room_screen.dart  # Create room + topic selection
    ├── join_room_screen.dart    # Join room with code
    ├── lobby_screen.dart        # Waiting room + role assignment
    └── game_screen.dart         # Card reveal + voting + results
```

## 🗄️ Database Schema

```sql
-- Rooms table
create table rooms (
  id text primary key,
  host_name text,
  topic text,
  word text,
  impostor_word text,
  status text default 'waiting',
  created_at timestamp default now()
);

-- Players table
create table players (
  id uuid primary key default gen_random_uuid(),
  room_id text references rooms(id),
  name text,
  is_impostor boolean default false,
  is_host boolean default false,
  voted_for text,
  created_at timestamp default now()
);
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x
- Android Studio or VS Code
- Supabase account

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/impostor-cards.git
cd impostor-cards
```

2. Install dependencies:
```bash
flutter pub get
```

3. Update Supabase credentials in `lib/main.dart`:
```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

4. Run the app:
```bash
flutter run
```

## 📸 Screenshots

| Home | Category | Lobby |
|------|----------|-------|
| ![Home](screenshots/home.jpg) | ![Category](screenshots/category.jpg) | ![Lobby](screenshots/lobby.jpg) |

| Card Reveal | Voting | Result |
|-------------|--------|--------|
| ![Card](screenshots/card.jpg) | ![Voting](screenshots/voting.jpg) | ![Result](screenshots/result.jpg) |

## 👥 Categories

- 🏏 Cricket
- 🎬 Movies
- 🌍 Countries
- 🍕 Food
- 💻 Technology
- ⚽ Sports
- 🦁 Animals
- 🎲 General Knowledge
- ⚡ Anime
- 🎮 Games

## 📄 License

This project is for educational purposes.

## 🙏 Acknowledgements

- Built with [Flutter](https://flutter.dev)
- Backend powered by [Supabase](https://supabase.com)
- Inspired by the physical Impostor Cards game
