# GridRun

Fast, skill-based neon arcade runner with global cloud-based leaderboards and progress tracking.

## Features

- **Campaign Mode**: Progress through 3 worlds with 5 levels each
- **Endless Mode**: Survive as long as possible with increasing difficulty
- **Global Leaderboards**: Compete with players worldwide
- **Cloud Save**: Your progress syncs across devices
- **Real-time Updates**: Live leaderboard updates powered by Supabase

## Technology Stack

- **Frontend**: HTML5, JavaScript, Phaser 3 game engine
- **Backend**: Supabase (Authentication, Database, Real-time)
- **Authentication**: Supabase Auth with email/password
- **Database**: PostgreSQL via Supabase
- **Real-time**: Supabase Realtime subscriptions

## Setup

### Quick Start (Development)

1. Clone the repository
2. Open `index_dev.html` in a web browser
3. **Note**: You'll need to configure Supabase for full functionality

### Supabase Setup (Required)

To enable authentication, cloud saves, and global leaderboards:

1. **Create a Supabase project** at [supabase.com](https://supabase.com)
2. **Configure your credentials** in `index_dev.html`:
   ```javascript
   const SUPABASE_URL = "YOUR_SUPABASE_URL";
   const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";
   ```
3. **Set up the database** by following the complete guide in [`SUPABASE_SETUP.md`](SUPABASE_SETUP.md)

### Documentation

- **[SUPABASE_SETUP.md](SUPABASE_SETUP.md)** - Complete Supabase configuration guide
- **[MIGRATION_SUMMARY.md](MIGRATION_SUMMARY.md)** - Details on the Supabase migration

## How to Play

1. **Create an account** or login (required)
2. **Select a mode**: Campaign or Endless
3. **Controls**: 
   - Desktop: WASD or Arrow keys
   - Mobile: Touch to move
4. **Survive**: Dodge obstacles and rack up points
5. **Compete**: Check the global leaderboards

## Game Modes

### Campaign
- 3 themed worlds with unique challenges
- 5 levels per world with increasing difficulty
- Bronze/Silver/Gold tier rankings
- Unlock new worlds by completing levels

### Endless
- Difficulty ramps from World 1 Level 1 → World 3 Level 5
- Plateau after ~120 seconds
- Special hazards appear over time
- Compete for the highest score globally

## Features in Detail

### Authentication
- Email/password sign up and login
- Secure authentication via Supabase Auth
- Editable usernames
- Cross-device session management

### Cloud Saves
- Game progress stored in cloud database
- Settings synced across devices  
- Never lose your progress

### Global Leaderboards
- 5 leaderboard categories:
  - Endless Best
  - Campaign Total
  - World 1 Total
  - World 2 Total
  - World 3 Total
- Real-time updates (optional)
- Top 25 rankings displayed

## Contributing

Contributions are welcome! Please feel free to submit pull requests.

## License

[Add your license here]

## Credits

Built with Phaser 3 and powered by Supabase.
