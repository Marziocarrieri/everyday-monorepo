import '../models/household.dart';
import '../repositories/household_repository.dart';
import 'auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class HouseholdService {
  final HouseholdRepository _repo = HouseholdRepository();
  final AuthService _auth = AuthService();

  Future<void> addMember({
    required String householdId,
    required String userId,
    required String role,
  }) async {
    final supabase = Supabase.instance.client;
    await supabase.from('household_member').insert({
      'household_id': householdId,
      'user_id': userId,
      'role': role,
      'member_status': 'ACTIVE',
    });
  }

  // Crea una nuova casa e coordina il lavoro
  Future<Household> createHousehold(String name) async {
    final supabase = Supabase.instance.client;

    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    final householdResponse = await supabase
        .from('household')
        .insert({
          'name': name,
          'created_by': user.id,
        })
        .select()
        .single();

    final householdId = householdResponse['id'];

    print('Creating membership with role HOST for user ${user.id}');

    await addMember(
      householdId: householdId,
      userId: user.id,
      role: 'HOST',
    );

    return Household.fromJson(householdResponse);
  }

  // Lista delle proprie case
  Future<List<Household>> getMyHouseholds() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    return await _repo.getHouseholdsForUser(user.id);
  }

  Future<HouseholdJoinResult> joinHouseholdByInviteCode({
    required String inviteCode,
    required String role,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      return await _repo.joinByInviteCode(
        userId: user.id,
        inviteCode: inviteCode.toUpperCase(),
        role: role,
      );
    } catch (error) {
      debugPrint('Error joining household by invite: $error');
      rethrow;
    }
  }
}