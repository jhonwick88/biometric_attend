import 'package:flutter/material.dart';
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
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(allAttendanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Seluruh User'),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: attendanceAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (history) {
                final filtered = _filterHistory(history);
                
                // Calculate counts per user
                final userCounts = <String, int>{};
                for (var att in filtered) {
                  final email = att.userEmail ?? 'Unknown User';
                  userCounts[email] = (userCounts[email] ?? 0) + 1;
                }

                // Get unique list of users who attended
                final uniqueUsers = userCounts.keys.toList()..sort();

                return Column(
                  children: [
                    _buildStatsBadge(filtered.length),
                    Expanded(
                      child: uniqueUsers.isEmpty 
                        ? const Center(child: Text('Tidak ada data absensi untuk periode ini.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: uniqueUsers.length,
                            itemBuilder: (context, index) {
                              final email = uniqueUsers[index];
                              final count = userCounts[email] ?? 0;
                              return _buildAttendanceSummaryCard(email, count);
                            },
                          ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(_selectedDateRange == null 
                ? 'Pilih Range Tanggal' 
                : '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}'),
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );
                if (range != null) setState(() => _selectedDateRange = range);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {
              _selectedDateRange = null;
              _selectedMonth = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBadge(int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2B32B2), Color(0xFF1488CC)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total Kehadiran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
            child: Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  List<AttendanceModel> _filterHistory(List<AttendanceModel> history) {
    return history.where((att) {
      if (att.checkIn == null) return false;
      
      if (_selectedDateRange != null) {
        // Normalize range boundaries
        final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);

        // Check if att.checkIn is within [start, end] inclusive
        return (att.checkIn!.isAtSameMomentAs(start) || att.checkIn!.isAfter(start)) &&
               (att.checkIn!.isAtSameMomentAs(end) || att.checkIn!.isBefore(end));
      }
      
      return true;
    }).toList();
  }

  Widget _buildAttendanceSummaryCard(String email, int count) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserAttendanceDetailPage(userEmail: email),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFFF6F91).withOpacity(0.1),
            child: Text(
              email.isNotEmpty ? email[0].toUpperCase() : '?',
              style: const TextStyle(color: Color(0xFFFF6F91), fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            email,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: const Text('Total kehadiran dlm periode ini'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6F91),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6F91).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Text(
              '$count Hari',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
