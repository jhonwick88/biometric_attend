import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../viewmodels/admin_viewmodel.dart';
import 'user_attendance_detail_page.dart';

class AllAttendancePage extends ConsumerStatefulWidget {
  const AllAttendancePage({super.key});

  @override
  ConsumerState<AllAttendancePage> createState() => _AllAttendancePageState();
}

class _AllAttendancePageState extends ConsumerState<AllAttendancePage> {
  DateTimeRange? _selectedDateRange;
  String? _selectedMonth;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    // Default filter: Hari ini
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(allAttendanceProvider);
    final usersAsync = ref.watch(allUsersProvider);

    // --- BRAND COLORS (Consistent with HomePage) ---
    const primaryColor = Color(0xFFFF6F91); // Soft Pink
    const accentColor = Color(0xFFFF9671); // Soft Orange
    const backgroundColor = Color(0xFFFFEEF2);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background Gradient Decorations
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.4),
              ),
            ),
          ),
          Positioned(
            top: 400,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.3),
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ---------------- CUSTOM SLIVER APP BAR ----------------
              SliverAppBar(
                expandedHeight: 120, // Tall enough for nice collapse animation
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                scrolledUnderElevation: 0,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      color: backgroundColor.withOpacity(0.5),
                      child: FlexibleSpaceBar(
                        titlePadding: const EdgeInsets.only(left: 54, right: 16, bottom: 16),
                        centerTitle: false,
                        title: const Text(
                          "Riwayat Team",
                          style: TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            fontSize: 21,
                          ),
                        ),
                        background: Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60, left: 54),
                            child: Text(
                              "ADMINISTRASI",
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryColor.withOpacity(0.8),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ---------------- STATS BOX ----------------
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: attendanceAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (history) {
                      final filtered = _filterHistory(history);
                      return _buildStatsCard(filtered.length);
                    },
                  ),
                ),
              ),

              // ---------------- STICKY SEARCH & FILTERS ----------------
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyFilterDelegate(
                  minHeight: 160,
                  maxHeight: 160,
                  child: Container(
                    color: backgroundColor, // Memblokir konten yang di-scroll di belakangnya
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Column(
                      children: [
                        _buildSearchField(),
                        const SizedBox(height: 12),
                        _buildFilterRow(),
                      ],
                    ),
                  ),
                ),
              ),

              // ---------------- ATTENDANCE LIST ----------------
              attendanceAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: primaryColor)),
                ),
                error: (err, stack) => SliverFillRemaining(
                  child: Center(child: Text('Error: $err')),
                ),
                data: (history) {
                  final filtered = _filterHistory(history);
                  
                  // Mapping email to username
                  final userMap = <String, String>{};
                  usersAsync.whenData((users) {
                    for (var user in users) {
                      userMap[user.email] = user.username;
                    }
                  });

                  // Calculate counts per user
                  final userCounts = <String, int>{};
                  for (var att in filtered) {
                    final email = att.userEmail ?? 'Unknown User';
                    userCounts[email] = (userCounts[email] ?? 0) + 1;
                  }

                  // Get unique list of users who attended and apply search
                  final uniqueUsers = userCounts.keys.where((email) {
                    final username = userMap[email]?.toLowerCase() ?? email.toLowerCase();
                    return username.contains(_searchQuery.toLowerCase());
                  }).toList()..sort();

                  if (uniqueUsers.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded, size: 80, color: primaryColor.withOpacity(0.1)),
                          const SizedBox(height: 16),
                          const Text(
                            'Tidak ada data absensi\nuntuk kriteria ini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black38, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final email = uniqueUsers[index];
                          final username = userMap[email] ?? email;
                          final count = userCounts[email] ?? 0;
                          return _buildAttendanceSummaryCard(email, username, count);
                        },
                        childCount: uniqueUsers.length,
                      ),
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6F91).withOpacity(0.18),
            blurRadius: 24,
            spreadRadius: 4,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        decoration: InputDecoration(
          hintText: "Cari nama atau email team...",
          hintStyle: const TextStyle(color: Colors.black38, fontSize: 13, fontWeight: FontWeight.normal),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 8.0, top: 4.0, bottom: 4.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFF6F91).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_rounded, color: Color(0xFFFF6F91), size: 20),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 56, minHeight: 40),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          filled: true,
          fillColor: Colors.transparent,
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.cancel_rounded, size: 22, color: Color(0xFFFF6F91)),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = "");
                },
              )
            : null,
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFFFF6F91),
                          onPrimary: Colors.white,
                          onSurface: Colors.black87,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (range != null) setState(() => _selectedDateRange = range);
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFF6F91).withOpacity(0.15), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6F91).withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6F91).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.date_range_rounded, size: 16, color: Color(0xFFFF6F91)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDateRange == null 
                          ? 'Filter Tanggal' 
                          : '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() {
              _selectedDateRange = null;
              _selectedMonth = null;
            }),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF6F91).withOpacity(0.15), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6F91).withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFFFF6F91)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(int count) {
    const primaryColor = Color(0xFFFF6F91);
    const accentColor = Color(0xFFFF9671);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Kehadiran Team",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                "Total dlm periode ini",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '$count Record',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  List<AttendanceModel> _filterHistory(List<AttendanceModel> history) {
    return history.where((att) {
      if (att.checkIn == null) return false;
      
      if (_selectedDateRange != null) {
        final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
        return (att.checkIn!.isAtSameMomentAs(start) || att.checkIn!.isAfter(start)) &&
               (att.checkIn!.isAtSameMomentAs(end) || att.checkIn!.isBefore(end));
      }
      return true;
    }).toList();
  }

  Widget _buildAttendanceSummaryCard(String email, String username, int count) {
    const primaryColor = Color(0xFFFF6F91);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserAttendanceDetailPage(userEmail: email)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF333333)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(fontSize: 12, color: Colors.black38, fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$count',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      const Text(
                        'HARI',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 8, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyFilterDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyFilterDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
