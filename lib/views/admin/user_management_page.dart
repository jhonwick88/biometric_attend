import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../viewmodels/admin_viewmodel.dart';

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  String _searchQuery = "";
  String _selectedRole = "ALL";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        titlePadding: const EdgeInsets.only(left: 54, bottom: 16),
                        centerTitle: false,
                        title: const Text(
                          "Kelola Team",
                          style: TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            fontSize: 21,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ---------------- STICKY SEARCH & FILTERS ----------------
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyFilterDelegate(
                  minHeight: 150,
                  maxHeight: 150,
                  child: Container(
                    color: backgroundColor,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // const Padding(
                        //   padding: EdgeInsets.only(left: 4),
                        //   child: Text(
                        //     "PENGATURAN",
                        //     style: TextStyle(
                        //       fontSize: 12,
                        //       color: Colors.black54,
                        //       fontWeight: FontWeight.bold,
                        //       letterSpacing: 1.0,
                        //     ),
                        //   ),
                        // ),
                        _buildSearchField(),
                        const SizedBox(height: 16),
                        _buildRoleFilterChips(),
                      ],
                    ),
                  ),
                ),
              ),

              // ---------------- USER LIST ----------------
              usersAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: primaryColor)),
                ),
                error: (err, stack) => SliverFillRemaining(
                  child: Center(child: Text('Error: $err')),
                ),
                data: (users) {
                  // Apply Filtering
                  final filteredUsers = users.where((u) {
                    final matchesSearch = u.username.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                          u.email.toLowerCase().contains(_searchQuery.toLowerCase());
                    final matchesRole = _selectedRole == "ALL" || u.role.toUpperCase() == _selectedRole;
                    return matchesSearch && matchesRole;
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline_rounded, size: 80, color: primaryColor.withOpacity(0.1)),
                          const SizedBox(height: 16),
                          const Text(
                            'Tidak ada user ditemukan.',
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
                        (context, index) => _buildUserCard(context, filteredUsers[index]),
                        childCount: filteredUsers.length,
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
          hintText: "Cari nama atau email...",
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

  Widget _buildRoleFilterChips() {
    final roles = ["ALL", "ADMIN", "USER", "DEV"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: roles.map((role) {
          final isSelected = _selectedRole == role;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(role),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedRole = role);
              },
              selectedColor: const Color(0xFFFF6F91),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              elevation: isSelected ? 4 : 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: isSelected ? Colors.transparent : Colors.black12),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    const primaryColor = Color(0xFFFF6F91);
    final bool isAdmin = user.role == 'admin' || user.role == 'dev';

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
          onTap: () {}, // Interaction could be expanded here
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: (isAdmin ? const Color(0xFFFF9671) : primaryColor).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                      style: TextStyle(color: isAdmin ? const Color(0xFFFF9671) : primaryColor, fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.username,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF333333)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.biometricEnabled)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(Icons.fingerprint_rounded, color: Color(0xFF4CAF50), size: 16),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(fontSize: 12, color: Colors.black38, fontWeight: FontWeight.normal),
                      ),
                      const SizedBox(height: 6),
                      _buildRoleBadge(user.role),
                    ],
                  ),
                ),
                _buildActionMenu(user),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    switch (role.toLowerCase()) {
      case 'admin':
        color = const Color(0xFF2B32B2);
        break;
      case 'dev':
        color = Colors.deepPurple;
        break;
      default:
        color = const Color(0xFFFF6F91);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildActionMenu(UserModel user) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Colors.black26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      onSelected: (value) {
        if (value == 'edit') {
          _showEditRoleDialog(context, user);
        } else if (value == 'delete') {
          _showDeleteDialog(context, user);
        } else if (value == 'reset_bio') {
          _showResetBiometricDialog(context, user);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('Ubah Role')]),
        ),
        if (user.biometricEnabled)
          const PopupMenuItem(
            value: 'reset_bio',
            child: Row(children: [Icon(Icons.fingerprint_rounded, size: 18), SizedBox(width: 8), Text('Reset Biometrik')]),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18), SizedBox(width: 8), Text('Hapus User', style: TextStyle(color: Colors.red))]),
        ),
      ],
    );
  }

  // --- DIALOGS (Styled) ---

  void _showResetBiometricDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reset Biometrik', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menonaktifkan fitur Quick Login untuk ${user.username}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.black38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6F91),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final updatedUser = user.copyWith(biometricEnabled: false);
              ref.read(adminControllerProvider.notifier).updateUser(updatedUser);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Biometrik berhasil di-reset!')),
              );
            },
            child: const Text('Reset Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditRoleDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedRole = user.role;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Ubah Role User', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: ['user', 'admin', 'dev'].map((role) {
                  return RadioListTile<String>(
                    title: Text(role.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    activeColor: const Color(0xFFFF6F91),
                    value: role,
                    groupValue: selectedRole,
                    onChanged: (value) {
                      setDialogState(() => selectedRole = value!);
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.black38))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6F91),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final updatedUser = user.copyWith(role: selectedRole);
                    ref.read(adminControllerProvider.notifier).updateUser(updatedUser);
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus User', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('Apakah Anda benar-benar yakin ingin menghapus ${user.email}? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.black38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              ref.read(adminControllerProvider.notifier).deleteUser(user.uid);
              Navigator.pop(context);
            },
            child: const Text('Hapus Permanen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
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
