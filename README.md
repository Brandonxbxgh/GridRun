# GridRun
Fast, skill-based neon arcade runner. Fully playable with or without authentication.

## Features

- 🎮 **Campaign Mode**: 3 worlds, 5 levels each with progressive difficulty
- ♾️ **Endless Mode**: Survive as long as you can with ramping challenge
- 🏆 **Global Leaderboards**: Real-time rankings across all players
- ☁️ **Cloud Sync**: Progress and settings sync across all your devices
- 🔐 **Secure Authentication**: Powered by Supabase Auth
- 📱 **Cross-Platform**: Works on desktop and mobile browsers
- 🎵 **Audio Support**: Optional music and sound effects
- 🌐 **Offline Support**: Falls back to local storage when offline

## Quick Start

1. Open `index_dev.html` in a web browser
2. Create an account or play offline
3. Use WASD/Arrow keys (desktop) or touch controls (mobile)
4. Survive and climb the leaderboards!

## Supabase Setup (Optional)

For cloud sync and global leaderboards:

1. See `SUPABASE_SETUP.md` for detailed setup instructions
2. Run the SQL schema from `supabase-schema.sql` in your Supabase project
3. Update credentials in `index_dev.html`:
   ```javascript
   const SUPABASE_URL = "https://your-project.supabase.co";
   const SUPABASE_ANON_KEY = "your-anon-key-here";
   ```

Without Supabase, the game works perfectly using local browser storage.

## Documentation

- **[Supabase Setup](SUPABASE_SETUP.md)** - Step-by-step Supabase configuration
- **[Migration Guide](MIGRATION_GUIDE.md)** - Migrating from localStorage to Supabase
- **[SQL Schema](supabase-schema.sql)** - Database structure and policies

## Tech Stack

- **Frontend**: Vanilla JavaScript, HTML5, CSS3
- **Game Engine**: Phaser 3
- **Backend**: Supabase (PostgreSQL + Auth + Realtime)
- **Storage**: LocalStorage (fallback) + Supabase (cloud)

## License

See repository for license details.
