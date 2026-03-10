import '../../data/models/household.dart';
import '../../data/repositories/household_repository.dart';
import '../../../../shared/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:everyday_app/features/personnel/data/models/household_member.dart';

class HouseholdService {
  final HouseholdRepository _repo;
  final AuthService _auth;

  HouseholdService({
    HouseholdRepository? householdRepository,
    AuthService? authService,
  }) : _repo = householdRepository ?? HouseholdRepository(),
       _auth = authService ?? AuthService();

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

    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final rawHouseholdResponse = await supabase
        .from('household')
        .insert({
          'name': name,
          'created_by': currentUserId,
        })
        .select()
        .single();

    final householdResponse = Map<String, dynamic>.from(rawHouseholdResponse);
    final householdId = householdResponse['id'] as String?;
    if (householdId == null || householdId.isEmpty) {
      throw Exception('Household creation failed: missing household id');
    }

    await addMember(
      householdId: householdId,
      userId: currentUserId,
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

  Future<List<HouseholdMember>> getMembers(String householdId) async {
    return await _repo.getMembers(householdId);
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
      // `role` is preserved in API for compatibility, but repository logic
      // always enforces invite.role as authoritative.
      return await _repo.joinByInviteCode(
        userId: user.id,
        userEmail: user.email,
        inviteCode: inviteCode.trim().toUpperCase(),
        role: role,
      );
    } catch (error) {
      debugPrint('Error joining household by invite: $error');
      rethrow;
    }
  }
}