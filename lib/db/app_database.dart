import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'vaultly.db');
    return openDatabase(
      path,
      version: 2,
      onConfigure: (db) {
        return db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE payments ADD COLUMN proof_path TEXT');
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE contacts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uid TEXT NOT NULL,
            name TEXT NOT NULL,
            phone TEXT,
            email TEXT,
            type TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uid TEXT NOT NULL,
            contact_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            given INTEGER NOT NULL,
            rate REAL NOT NULL,
            rate_type TEXT NOT NULL,
            start_date INTEGER NOT NULL,
            due_date INTEGER,
            notes TEXT,
            settled_at INTEGER,
            FOREIGN KEY (contact_id) REFERENCES contacts (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            transaction_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            date INTEGER NOT NULL,
            mode TEXT NOT NULL,
            note TEXT,
            proof_path TEXT,
            FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('CREATE INDEX idx_tx_uid ON transactions (uid)');
        await db.execute('CREATE INDEX idx_contact_uid ON contacts (uid)');
        await db.execute('CREATE INDEX idx_pay_tx ON payments (transaction_id)');
      },
    );
  }
}
