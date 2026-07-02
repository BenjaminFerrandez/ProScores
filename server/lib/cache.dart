import 'package:sqlite3/sqlite3.dart';

class CachedResponse {
  final String body;
  final int status;
  final int ageSeconds;
  const CachedResponse(this.body, this.status, this.ageSeconds);
}

/// A tiny SQLite-backed response cache with per-entry TTL.
///
/// `ttl <= 0` means "never expires" — used for data that doesn't change
/// (team id resolution, flags, squads...).
class Cache {
  final Database _db;
  Cache(this._db) {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS cache(
        key        TEXT PRIMARY KEY,
        body       TEXT NOT NULL,
        status     INTEGER NOT NULL,
        fetched_at INTEGER NOT NULL,
        ttl        INTEGER NOT NULL
      );
    ''');
  }

  factory Cache.open(String path) => Cache(sqlite3.open(path));

  int get _now => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// Returns a fresh cached entry, or null on miss / expiry.
  CachedResponse? get(String key) {
    final rows = _db.select(
        'SELECT body, status, fetched_at, ttl FROM cache WHERE key = ?',
        [key]);
    if (rows.isEmpty) return null;
    final r = rows.first;
    final fetchedAt = r['fetched_at'] as int;
    final ttl = r['ttl'] as int;
    final age = _now - fetchedAt;
    if (ttl > 0 && age >= ttl) return null; // expired
    return CachedResponse(r['body'] as String, r['status'] as int, age);
  }

  void put(String key, String body, int status, int ttl) {
    _db.execute(
      'INSERT OR REPLACE INTO cache(key, body, status, fetched_at, ttl) '
      'VALUES (?, ?, ?, ?, ?)',
      [key, body, status, _now, ttl],
    );
  }

  /// Number of stored entries (for the /health endpoint).
  int get size =>
      (_db.select('SELECT COUNT(*) AS n FROM cache').first['n'] as int);

  void close() => _db.dispose();
}
