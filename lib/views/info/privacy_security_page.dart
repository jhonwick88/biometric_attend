import 'package:flutter/material.dart';
import 'dart:ui';

class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF6F91);
    const accentColor = Color(0xFFFF9671);
    const backgroundColor = Color(0xFFFFEEF2);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background Decorations
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
            bottom: -150,
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
                      child: const FlexibleSpaceBar(
                        titlePadding: EdgeInsets.only(left: 54, right: 16, bottom: 16),
                        centerTitle: false,
                        title: Text(
                          "Privasi & Keamanan",
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
                            padding: EdgeInsets.only(top: 60, left: 54),
                            child: Text(
                              "KEPERCAYAAN ANDA",
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

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildInfoCard(
                      icon: Icons.fingerprint_rounded,
                      title: "Keamanan Biometrik",
                      description: "Data sidik jari Anda tidak pernah dikirim ke server kami. Bio-Attend menggunakan protokol Android Keystore untuk memastikan proses verifikasi hanya terjadi di dalam perangkat Anda.",
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 20),
                    _buildInfoCard(
                      icon: Icons.cloud_done_rounded,
                      title: "Enkripsi Data Cloud",
                      description: "Data absensi Anda disimpan dengan aman di Google Firebase. Seluruh komunikasi data antara aplikasi dan cloud menggunakan protokol TLS yang telah terenkripsi.",
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 20),
                    _buildInfoCard(
                      icon: Icons.location_on_rounded,
                      title: "Privasi Lokasi",
                      description: "Lokasi hanya dilacak saat Anda melakukan proses 'Absen'. Kami tidak memantau pergerakan Anda secara real-time di luar gerbang absensi yang ditentukan.",
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 20),
                    _buildInfoCard(
                      icon: Icons.notifications_active_rounded,
                      title: "Otoritas Notifikasi",
                      description: "Aplikasi hanya mengirimkan pengingat absensi sesuai dengan jadwal yang Anda atur sendiri di menu pengaturan. Tidak ada notifikasi pemasaran yang mengganggu.",
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 40),
                    const Center(
                      child: Text(
                        "Bio-Attend v1.0.0\nPerlindungan Privasi Terjamin.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black26, fontSize: 13, height: 1.5),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: primaryColor, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.6),
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
