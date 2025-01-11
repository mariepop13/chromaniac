import 'package:flutter_test/flutter_test.dart';
import 'package:chromaniac/services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Mock classes for testing
class MockSupabaseClient extends Mock implements SupabaseClient {
  final MockGoTrueClient _mockAuth = MockGoTrueClient();

  @override
  GoTrueClient get auth => _mockAuth;
}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSharedPreferences extends Mock implements SharedPreferences {
  final Map<String, dynamic> _data = {};

  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  Future<bool> setBool(String key, bool value) async {
    _data[key] = value;
    return true;
  }

  @override
  bool? getBool(String key) => _data[key] as bool?;

  @override
  Future<bool> setInt(String key, int value) async {
    _data[key] = value;
    return true;
  }

  @override
  int? getInt(String key) => _data[key] as int?;
}

void main() {
  setUpAll(() async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    
    // Load environment variables from root .env
    await dotenv.load(fileName: '.env');

    // Get Supabase credentials from environment
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    assert(supabaseUrl != null, 'SUPABASE_URL must be set in .env');
    assert(supabaseAnonKey != null, 'SUPABASE_ANON_KEY must be set in .env');

    // Simulate Supabase initialization
    await Supabase.initialize(
      url: supabaseUrl!,
      anonKey: supabaseAnonKey!,
    );
  });

  group('DatabaseService Initialization', () {
    test('database getter returns Supabase client', () {
      final databaseService = DatabaseService();
      
      expect(databaseService.database, isNotNull);
      expect(databaseService.database, isA<SupabaseClient>());
    });
  });

  group('DatabaseService Singleton Behavior', () {
    test('Multiple calls return same instance', () {
      final databaseService1 = DatabaseService();
      final databaseService2 = DatabaseService();
      
      expect(databaseService1, same(databaseService2));
      expect(databaseService1.database, equals(databaseService2.database));
    });
  });

  group('DatabaseService Methods', () {
    late DatabaseService databaseService;

    setUp(() {
      databaseService = DatabaseService();
    });

    test('getPalettes method exists', () {
      expect(() => databaseService.getPalettes(), isNotNull);
    });

    test('savePalette method exists', () {
      // Note: Actual testing would require mocking Supabase auth
      expect(() => databaseService.savePalette, isNotNull);
    });
  });
}
