import '../database/database_helper.dart';
import '../models/user.dart';

/// Repository for users. MVP uses a single hardcoded user.
class UserRepository {
  UserRepository(this._db);

  final DatabaseHelper _db;

  /// Default MVP user ID - consistent across app launches.
  static const String defaultUserId = '00000000-0000-0000-0000-000000000001';

  /// Get or create the default MVP user.
  Future<User> getOrCreateDefaultUser() async {
    final existing = await getById(defaultUserId);
    if (existing != null) return existing;
    return await _createDefaultUser();
  }

  Future<User> _createDefaultUser() async {
    final db = await _db.database;
    final now = DateTime.now();
    final user = User(
      id: defaultUserId,
      name: 'Game Master',
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('users', user.toMap());
    return user;
  }

  Future<User?> getById(String id) async {
    final db = await _db.database;
    final results = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  Future<void> update(User user) async {
    final db = await _db.database;
    await db.update(
      'users',
      user.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
}
