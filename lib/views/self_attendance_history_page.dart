import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../viewmodels/self_attendance_viewmodel.dart';
import '../models/attendance_model.dart';
import '../viewmodels/config_viewmodel.dart';

class SelfAttendanceHistoryPage extends ConsumerStatefulWidget {
  const SelfAttendanceHistoryPage({super.key});

  @override
  ConsumerState<SelfAttendanceHistoryPage> createState() => _SelfAttendanceHistoryPageState();
}

class _SelfAttendanceHistoryPageState extends ConsumerState<SelfAttendanceHistoryPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(selfAttendanceHistoryProvider.notifier).fetchNextPage();
    }
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(selfAttendanceHistoryProvider);
    final config = ref.watch(appConfigProvider).value;
    final breakMinutes = config?.breakTimeMinutes ?? 30;

    const primaryColor = Color(0xFFFF6F91); // Soft Pink
    const backgroundColor = Color(0xFFFFEEF2);
    const successColor = Color(0xFF4CAF50);
    const warningColor = Color(0xFFFF9671);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Riwayat Kehadiran (3 Bln)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(selfAttendanceHistoryProvider.notifier).refresh(),
        color: primaryColor,
        child: state.items.isEmpty && !state.isLoading
            ? ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Text(
                      'Belum ada data history dalam 3 bulan terakhir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black45, fontSize: 16),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                itemCount: state.items.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator(color: primaryColor)),
                    );
                  }

                  final att = state.items[index];
                  final isCheckOut = att.checkOut != null;
                  final timeFormat = DateFormat('HH:mm');
                  final duration = _calculateDuration(att.checkIn, att.checkOut, breakMinutes);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.calendar_today_rounded,
                                color: primaryColor.withOpacity(0.5),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    att.date,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF333333)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isCheckOut ? 'Selesai' : 'Sedang Bekerja',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isCheckOut ? successColor : warningColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTimeBadge("IN", att.checkIn != null ? timeFormat.format(att.checkIn!) : "--", successColor),
                            _buildTimeBadge("OUT", att.checkOut != null ? timeFormat.format(att.checkOut!) : "--", warningColor),
                            _buildTimeBadge("WORK", duration, primaryColor),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildTimeBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }
}
