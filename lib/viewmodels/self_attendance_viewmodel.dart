import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_model.dart';
import 'attendance_viewmodel.dart';
import 'auth_viewmodel.dart';

class SelfAttendanceHistoryState {
  final List<AttendanceModel> items;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;

  SelfAttendanceHistoryState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDoc,
  });

  SelfAttendanceHistoryState copyWith({
    List<AttendanceModel>? items,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
  }) {
    return SelfAttendanceHistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: lastDoc ?? this.lastDoc,
    );
  }
}

class SelfAttendanceHistoryNotifier extends Notifier<SelfAttendanceHistoryState> {
  @override
  SelfAttendanceHistoryState build() {
    // Initial fetch
    Future.microtask(() => fetchNextPage());
    return SelfAttendanceHistoryState();
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      state = state.copyWith(isLoading: false, hasMore: false);
      return;
    }

    try {
      final repo = ref.read(attendanceRepositoryProvider);
      final snapshot = await repo.getAttendanceHistoryPaginated(
        uid: user.uid,
        lastDoc: state.lastDoc,
        limit: 10,
      );

      final newItems = snapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
          .toList();

      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoading: false,
        hasMore: newItems.length == 10,
        lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // You might want to handle error state more explicitly here
    }
  }

  Future<void> refresh() async {
    state = SelfAttendanceHistoryState();
    await fetchNextPage();
  }
}

final selfAttendanceHistoryProvider =
    NotifierProvider<SelfAttendanceHistoryNotifier, SelfAttendanceHistoryState>(
        SelfAttendanceHistoryNotifier.new);
