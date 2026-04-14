import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/config_viewmodel.dart';

class UserAttendanceDetailPage extends ConsumerStatefulWidget {
  final String userEmail;

  const UserAttendanceDetailPage({super.key, required this.userEmail});

  @override
  ConsumerState<UserAttendanceDetailPage> createState() => _UserAttendanceDetailPageState();
}

class _UserAttendanceDetailPageState extends ConsumerState<UserAttendanceDetailPage> {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    // Default: 30 hari terakhir
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
  }

  String _calculateDuration(DateTime? start, DateTime? end, int breakMinutes) {
    if (start == null || end == null) return '-';
    final diff = end.difference(start);
    final totalMinutes = diff.inMinutes - breakMinutes;
    
    if (totalMinutes <= 0) return '0 Jam 0 Menit';
    
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '$hours Jam $minutes Menit';
  }

  List<AttendanceModel> _filterUserHistory(List<AttendanceModel> history) {
    return history.where((att) {
      // Filter by email
      if (att.userEmail != widget.userEmail) return false;
      if (att.checkIn == null) return false;

      // Filter by range
      if (_selectedDateRange != null) {
        final dayStart = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        final dayEnd = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
        
        return (att.checkIn!.isAtSameMomentAs(dayStart) || att.checkIn!.isAfter(dayStart)) &&
               (att.checkIn!.isAtSameMomentAs(dayEnd) || att.checkIn!.isBefore(dayEnd));
      }
      return true;
    }).toList();
  }

  List<double> _getDailyWorkHours(List<AttendanceModel> history) {
    if (_selectedDateRange == null) return [];
    
    // "yyyy-MM-dd" -> decimal hours
    Map<String, double> workHoursMap = {};
    for (var att in history) {
      if (att.checkIn != null && att.checkOut != null) {
        final config = ref.read(appConfigProvider).value;
        final breakMinutes = config?.breakTimeMinutes ?? 30;
        final totalMinutes = att.checkOut!.difference(att.checkIn!).inMinutes - breakMinutes;
        final hours = (totalMinutes > 0 ? totalMinutes : 0) / 60.0;
        workHoursMap[att.date] = hours;
      }
    }

    List<double> dailyHours = [];
    DateTime current = _selectedDateRange!.start;
    while (!current.isAfter(_selectedDateRange!.end)) {
      final dateKey = DateFormat('yyyy-MM-dd').format(current);
      dailyHours.add(workHoursMap[dateKey] ?? 0.0);
      current = current.add(const Duration(days: 1));
    }
    return dailyHours;
  }

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(allAttendanceProvider);
    final usersAsync = ref.watch(allUsersProvider);

    // --- BRAND COLORS ---
    const primaryColor = Color(0xFFFF6F91);
    const backgroundColor = Color(0xFFFFEEF2);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: attendanceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: primaryColor)),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (history) {
          final userHistory = _filterUserHistory(history);
          final dailyHours = _getDailyWorkHours(userHistory);
          
          // Get username
          String username = widget.userEmail;
          usersAsync.whenData((users) {
            final user = users.cast<UserModel?>().firstWhere((u) => u?.email == widget.userEmail, orElse: () => null);
            if (user != null) username = user.username;
          });

          // Sort by date descending for the list
          final sortedHistory = List<AttendanceModel>.from(userHistory);
          sortedHistory.sort((a, b) => (b.checkIn ?? DateTime(0)).compareTo(a.checkIn ?? DateTime(0)));

          // Calculate Absences
          int totalDays = 0;
          if (_selectedDateRange != null) {
            totalDays = _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays + 1;
          }
          final int absences = (totalDays - userHistory.length).clamp(0, totalDays);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ---------------- CUSTOM SLIVER APP BAR ----------------
              SliverAppBar(
                expandedHeight: 120,
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
                        title: Text(
                          username,
                          style: const TextStyle(
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
                            child: const Text(
                              "DETAIL KEHADIRAN",
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryColor,
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

              // ---------------- USER HEADER & STATS ----------------
              SliverToBoxAdapter(
                child: _buildUserHeader(username, userHistory.length, absences, dailyHours),
              ),

              // ---------------- FILTER BAR ----------------
              SliverToBoxAdapter(
                child: _buildFilterBar(),
              ),

              // ---------------- RECORD LIST ----------------
              sortedHistory.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(child: Text('Tidak ada riwayat untuk periode ini.')),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final config = ref.watch(appConfigProvider).value;
                            final breakMinutes = config?.breakTimeMinutes ?? 30;
                            return _buildRecordCard(sortedHistory[index], breakMinutes);
                          },
                          childCount: sortedHistory.length,
                        ),
                      ),
                    ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserHeader(String name, int totalAttendance, int absences, List<double> chartData) {
    const primaryColor = Color(0xFFFF6F91);
    const accentColor = Color(0xFFFF9671);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${chartData.fold<double>(0, (p, c) => p + c).toStringAsFixed(1)} Jam',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Total Jam Terbang ($name)",
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _buildStatBadge('Hadir', '$totalAttendance'),
                    const SizedBox(width: 8),
                    _buildStatBadge('Absen', '$absences'),
                  ],
                ),
              ],
            ),
          ),
          // Grafik
          Container(
            height: 90,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: _buildPerformanceChart(chartData),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(List<double> data) {
    if (data.isEmpty) return const SizedBox.shrink();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.asMap().entries.map((entry) {
        final hours = entry.value;
        // Normalisasi tinggi (Maksimal 12 jam)
        final double normalizedHeight = (hours / 12.0).clamp(0.05, 1.0);
        
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 0.5), // "Dempet"
            height: 80 * normalizedHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                   HSVColor.fromAHSV(1.0, (entry.key * 20) % 360, 0.7, 0.9).toColor(),
                   HSVColor.fromAHSV(1.0, (entry.key * 20 + 30) % 360, 0.8, 1.0).toColor(),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              boxShadow: hours > 0 ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ] : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.date_range, size: 18, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
          TextButton.icon(
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('Filter'),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
                initialDateRange: _selectedDateRange,
              );
              if (range != null) {
                setState(() => _selectedDateRange = range);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(AttendanceModel att, int breakMinutes) {
    final formatTime = DateFormat('HH:mm');
    final duration = _calculateDuration(att.checkIn, att.checkOut, breakMinutes);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      att.date,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: att.checkOut != null ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    att.checkOut != null ? 'Selesai' : 'Aktif',
                    style: TextStyle(
                      color: att.checkOut != null ? Colors.green.shade700 : Colors.orange.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _buildTimeInfo('Masuk', att.checkIn != null ? formatTime.format(att.checkIn!) : '--:--', Icons.login_rounded, Colors.blue),
                const Spacer(),
                _buildTimeInfo('Pulang', att.checkOut != null ? formatTime.format(att.checkOut!) : '--:--', Icons.logout_rounded, Colors.orange),
                const Spacer(),
                _buildTimeInfo('Jam Kerja', duration, Icons.timer_outlined, const Color(0xFFFF6F91)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
      ],
    );
  }
}
