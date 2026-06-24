// import 'dart:typed_data';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../core/constants/app_constants.dart';

// /// Supabase Service - Handles authentication and database operations
// class SupabaseService {
//   static SupabaseService? _instance;
//   late final SupabaseClient _client;

//   SupabaseService._internal();

//   static SupabaseService get instance {
//     _instance ??= SupabaseService._internal();
//     return _instance!;
//   }

//   /// Initialize Supabase
//   Future<void> initialize() async {
//     await Supabase.initialize(
//       url: AppConstants.supabaseUrl,
//       anonKey: AppConstants.supabaseAnonKey,
//     );
//     _client = Supabase.instance.client;
//   }

//   /// Get Supabase client
//   SupabaseClient get client => _client;

//   /// Get current user
//   User? get currentUser => _client.auth.currentUser;

//   /// Check if user is authenticated
//   bool get isAuthenticated => currentUser != null;

//   /// Get current user ID
//   String? get currentUserId => currentUser?.id;

//   // ==================== AUTHENTICATION ====================

//   /// Sign up with email and password
//   Future<AuthResponse> signUp({
//     required String email,
//     required String password,
//     Map<String, dynamic>? userData,
//   }) async {
//     try {
//       print('🔄 SupabaseService: Attempting signup for $email');
//       final response = await _client.auth.signUp(
//         email: email,
//         password: password,
//         data: userData,
//       );
//       print('✅ SupabaseService: Signup response received - User ID: ${response.user?.id}');
//       return response;
//     } catch (e) {
//       print('❌ SupabaseService: Signup error: $e');
//       rethrow;
//     }
//   }

//   /// Sign in with email and password
//   Future<AuthResponse> signIn({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       print('🔄 SupabaseService: Attempting signin for $email');
//       final response = await _client.auth.signInWithPassword(
//         email: email,
//         password: password,
//       );
//       print('✅ SupabaseService: Signin response received - User ID: ${response.user?.id}');
//       return response;
//     } catch (e) {
//       print('❌ SupabaseService: Signin error: $e');
//       rethrow;
//     }
//   }

//   /// Sign out
//   Future<void> signOut() async {
//     try {
//       await _client.auth.signOut();
//     } catch (e) {
//       rethrow;
//     }
//   }

//   /// Reset password
//   Future<void> resetPassword(String email) async {
//     try {
//       await _client.auth.resetPasswordForEmail(email);
//     } catch (e) {
//       rethrow;
//     }
//   }

//   /// Update user profile
//   Future<UserResponse> updateUserProfile(Map<String, dynamic> data) async {
//     try {
//       final response = await _client.auth.updateUser(
//         UserAttributes(data: data),
//       );
//       return response;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   // ==================== USER PROFILES ====================

//   /// Check if email already exists
//   Future<bool> emailExists(String email) async {
//     try {
//       final response = await _client
//           .from('user_profiles')
//           .select('id')
//           .eq('email', email.toLowerCase())
//           .maybeSingle();
//       return response != null;
//     } catch (e) {
//       return false;
//     }
//   }

//   /// Get user profile
//   Future<Map<String, dynamic>?> getUserProfile(String userId) async {
//     try {
//       final response = await _client
//           .from('user_profiles')
//           .select()
//           .eq('id', userId)
//           .maybeSingle();
//       return response;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   /// Update user profile in database
//   Future<Map<String, dynamic>> updateUserProfileData(
//     String userId,
//     Map<String, dynamic> profileData,
//   ) async {
//     try {
//       final response = await _client
//           .from('user_profiles')
//           .update(profileData)
//           .eq('id', userId)
//           .select()
//           .single();
//       return response;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   /// Update last login timestamp
//   Future<void> updateLastLogin(String userId) async {
//     try {
//       await _client
//           .from('user_profiles')
//           .update({'last_login_at': DateTime.now().toIso8601String()})
//           .eq('id', userId);
//     } catch (e) {
//       // Don't throw - last login update is not critical
//     }
//   }

//   // ==================== ANIMALS ====================

//   /// Create a new animal
//   Future<Map<String, dynamic>> createAnimal(Map<String, dynamic> animalData) async {
//     try {
//       final response = await _client
//           .from(AppConstants.animalsTable)
//           .insert(animalData)
//           .select()
//           .single();
//       return response;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   /// Get all animals for current user
//   Future<List<Map<String, dynamic>>> getAnimals() async {
//     try {
//       if (currentUserId == null) {
//         throw Exception('User not authenticated');
//       }

//       final response = await _client
//           .from(AppConstants.animalsTable)
//           .select()
//           .eq('user_id', currentUserId!)
//           .order('created_at', ascending: false);

//       return List<Map<String, dynamic>>.from(response);
//     } catch (e) {
//       rethrow;
//     }
//   }

//   /// Get animal by ID
//   Future<Map<String, dynamic>> getAnimalById(String animalId) async {
//     try {
//       final response = await _client
//           .from(AppConstants.animalsTable)
//           .select()
//           .eq('id', animalId)
//           .single();
//       return response;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   /// Update animal
//   Future<Map<String, dynamic>> updateAnimal(
//     String animalId,
//     Map<String, dynamic> updates,
//   ) async {
//     try {
//       final response = await _client
//           .from(AppConstants.animalsTable)
//           .update(updates)
//           .eq('id', animalId)
//           .select()
//           .single();
//       return response;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   /// Delete animal
//   Future<void> deleteAnimal(String animalId) async {
//     try {
//       await _client
//           .from(AppConstants.animalsTable)
//           .delete()
//           .eq('id', animalId);
//     } catch (e) {
//       rethrow;
//     }
//   }

//   // ==================== MOVEMENT DATA ====================

//   /// Create movement data record
//   Future<Map<String, dynamic>> createMovementData(
//     Map<String, dynamic> movementData,
//   ) async {
//     try {
//       final response = await _client
//           .from(AppConstants.movementDataTable)
//           .insert(movementData)
//           .select()
//           .single();
//       return response;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   /// Get movement data for an animal
//   Future<List<Map<String, dynamic>>> getMovementData({
//     required String animalId,
//     DateTime? startDate,
//     DateTime? endDate,
//     int? limit,
//   }) async {
//     try {
//       var query = _client
//           .from(AppConstants.movementDataTable)
//           .select()
//           .eq('animal_id', animalId);

//       if (startDate != null) {
//         query = query.gte('date', startDate.toIso8601String());
//       }

//       if (endDate != null) {
//         query = query.lte('date', endDate.toIso8601String());
//       }

//       var orderedQuery = query.order('date', ascending: false);

//       if (limit != null) {
//         orderedQuery = orderedQuery.limit(limit);
//       }

//       final response = await orderedQuery;
//       return List<Map<String, dynamic>>.from(response);
//     } catch (e) {
//       rethrow;
//     }
//   }

//   /// Get latest movement data for an animal
//   Future<Map<String, dynamic>?> getLatestMovementData(String animalId) async {
//     try {
//       final response = await _client
//           .from(AppConstants.movementDataTable)
//           .select()
//           .eq('animal_id', animalId)
//           .order('timestamp', ascending: false)
//           .limit(1);

//       if (response.isEmpty) return null;
//       return response.first;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   // ==================== LAMENESS RECORDS ====================

//   /// Create lameness record
//   Future<Map<String, dynamic>> createLamenessRecord(
//     Map<String, dynamic> lamenessData,
//   ) async {
//     try {
//       final response = await _client
//           .from(AppConstants.lamenessRecordsTable)
//           .insert(lamenessData)
//           .select()
//           .single();
//       return response;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   /// Get lameness records for an animal
//   Future<List<Map<String, dynamic>>> getLamenessRecords({
//     required String animalId,
//     int? limit,
//   }) async {
//     try {
//       var query = _client
//           .from(AppConstants.lamenessRecordsTable)
//           .select()
//           .eq('animal_id', animalId)
//           .order('detection_date', ascending: false);

//       if (limit != null) {
//         query = query.limit(limit);
//       }

//       final response = await query;
//       return List<Map<String, dynamic>>.from(response);
//     } catch (e) {
//       rethrow;
//     }
//   }

//   /// Get latest lameness record for an animal
//   Future<Map<String, dynamic>?> getLatestLamenessRecord(String animalId) async {
//     try {
//       final response = await _client
//           .from(AppConstants.lamenessRecordsTable)
//           .select()
//           .eq('animal_id', animalId)
//           .order('detection_date', ascending: false)
//           .limit(1);

//       if (response.isEmpty) return null;
//       return response.first;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   // ==================== VIDEO RECORDS ====================

//   /// Create video record
//   Future<Map<String, dynamic>> createVideoRecord(
//     Map<String, dynamic> videoData,
//   ) async {
//     try {
//       final response = await _client
//           .from(AppConstants.videoRecordsTable)
//           .insert(videoData)
//           .select()
//           .single();
//       return response;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   /// Get video records for an animal
//   Future<List<Map<String, dynamic>>> getVideoRecords({
//     required String animalId,
//     int? limit,
//   }) async {
//     try {
//       var query = _client
//           .from(AppConstants.videoRecordsTable)
//           .select()
//           .eq('animal_id', animalId)
//           .order('upload_date', ascending: false);

//       if (limit != null) {
//         query = query.limit(limit);
//       }

//       final response = await query;
//       return List<Map<String, dynamic>>.from(response);
//     } catch (e) {
//       rethrow;
//     }
//   }

//   /// Update video processing status
//   Future<Map<String, dynamic>> updateVideoProcessingStatus({
//     required String videoId,
//     required String status,
//     Map<String, dynamic>? results,
//     String? errorMessage,
//   }) async {
//     try {
//       final updates = <String, dynamic>{
//         'processing_status': status,
//       };

//       if (results != null) {
//         updates['analysis_results'] = results;
//       }

//       if (errorMessage != null) {
//         updates['error_message'] = errorMessage;
//       }

//       final response = await _client
//           .from(AppConstants.videoRecordsTable)
//           .update(updates)
//           .eq('id', videoId)
//           .select()
//           .single();

//       return response;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   // ==================== STORAGE ====================

//   /// Upload file to storage
//   Future<String> uploadFile({
//     required String bucket,
//     required String path,
//     required List<int> fileBytes,
//     String? contentType,
//   }) async {
//     try {
//       await _client.storage.from(bucket).uploadBinary(
//             path,
//             Uint8List.fromList(fileBytes),
//             fileOptions: FileOptions(
//               contentType: contentType,
//             ),
//           );

//       final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
//       return publicUrl;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   /// Delete file from storage
//   Future<void> deleteFile({
//     required String bucket,
//     required String path,
//   }) async {
//     try {
//       await _client.storage.from(bucket).remove([path]);
//     } catch (e) {
//       rethrow;
//     }
//   }

//   /// Get public URL for file
//   String getPublicUrl({
//     required String bucket,
//     required String path,
//   }) {
//     return _client.storage.from(bucket).getPublicUrl(path);
//   }

//   // ==================== REAL-TIME SUBSCRIPTIONS ====================

//   /// Subscribe to animal updates
//   RealtimeChannel subscribeToAnimals(void Function(PostgresChangePayload) callback) {
//     return _client
//         .channel('animals_channel')
//         .onPostgresChanges(
//           event: PostgresChangeEvent.all,
//           schema: 'public',
//           table: AppConstants.animalsTable,
//           callback: callback,
//         )
//         .subscribe();
//   }

//   /// Subscribe to movement data updates
//   RealtimeChannel subscribeToMovementData(
//     String animalId,
//     void Function(PostgresChangePayload) callback,
//   ) {
//     return _client
//         .channel('movement_data_channel_$animalId')
//         .onPostgresChanges(
//           event: PostgresChangeEvent.all,
//           schema: 'public',
//           table: AppConstants.movementDataTable,
//           filter: PostgresChangeFilter(
//             type: PostgresChangeFilterType.eq,
//             column: 'animal_id',
//             value: animalId,
//           ),
//           callback: callback,
//         )
//         .subscribe();
//   }

//   /// Unsubscribe from channel
//   Future<void> unsubscribe(RealtimeChannel channel) async {
//     await _client.removeChannel(channel);
//   }
// }
