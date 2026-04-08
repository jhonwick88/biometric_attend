import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../viewmodels/admin_viewmodel.dart';

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
                return Column(
                  children: [
                    _buildStatsBadge(filtered.length),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final att = filtered[index];
                          return _buildAttendanceCard(att);
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
      
      bool dateMatch = true;
      if (_selectedDateRange != null) {
        dateMatch = att.checkIn!.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                    att.checkIn!.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }
      
      return dateMatch;
    }).toList();
  }

  Widget _buildAttendanceCard(AttendanceModel att) {
    final formatTime = DateFormat('HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        title: Text(att.userEmail ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${att.date} • In: ${att.checkIn != null ? formatTime.format(att.checkIn!) : '-'} • Out: ${att.checkOut != null ? formatTime.format(att.checkOut!) : '-'}'),
        trailing: Icon(
          att.checkOut != null ? Icons.check_circle : Icons.pending,
          color: att.checkOut != null ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}
