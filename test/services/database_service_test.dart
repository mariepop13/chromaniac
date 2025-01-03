import 'package:flutter_test/flutter_test.dart';
import 'package:chromaniac/services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mockito/mockito.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late DatabaseService databaseService;
  late MockSupabaseClient mockSupabaseClient;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    databaseService = DatabaseService();
  });

  test('database getter returns Supabase client', () {
    expect(databaseService.database, isNotNull);
    expect(databaseService.database, isA<SupabaseClient>());
  });

  test('DatabaseService is a singleton', () {
    final instance1 = DatabaseService();
    final instance2 = DatabaseService();
    expect(instance1, same(instance2));
  });
}