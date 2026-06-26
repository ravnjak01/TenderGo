import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/admin_dto.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/models/requests/users_search_request.dart';
import 'package:tendergo/shared/services/admin_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';

class AdminUsersPanel extends StatefulWidget {
  const AdminUsersPanel({super.key});

  @override
  State<AdminUsersPanel> createState() => _AdminUsersPanelState();
}

class _AdminUsersPanelState extends State<AdminUsersPanel> {
  final TextEditingController _searchController = TextEditingController();
  late final AdminService _adminService;
  List<UserDto> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _adminService = AdminService(DioClient.getDio());
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers({String searchTerm = ''}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final request = UsersSearchRequest(
        searchTerm: searchTerm.isEmpty ? null : searchTerm,
      );

      final users = await _adminService.search(request);
      if (!mounted) return;

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleBanUser(UserDto user) async {
    final reason = await _showBanReasonDialog();
    if (reason == null || reason.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _adminService.banUser(user.id, BanRequest(reason: reason));
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: response.success ? Colors.green : Colors.red,
        ),
      );

      if (response.success) {
        setState(() {
          _users = _users.map((u) {
            if (u.id == user.id) {
              return UserDto(
                id: u.id,
                email: u.email,
                username: u.username,
                firstName: u.firstName,
                lastName: u.lastName,
                address: u.address,
                profileImageUrl: u.profileImageUrl,
                roles: u.roles,
                isBanned: true,
              );
            }
            return u;
          }).toList();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _handleUnbanUser(UserDto user) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _adminService.unbanUser(user.id);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: response.success ? Colors.green : Colors.red,
        ),
      );

      if (response.success) {
        setState(() {
          _users = _users.map((u) {
            if (u.id == user.id) {
              return UserDto(
                id: u.id,
                email: u.email,
                username: u.username,
                firstName: u.firstName,
                lastName: u.lastName,
                address: u.address,
                profileImageUrl: u.profileImageUrl,
                roles: u.roles,
                isBanned: false,
              );
            }
            return u;
          }).toList();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<String?> _showBanReasonDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban korisnika'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Razlog zabrane',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Otka�i'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Potvrdi'),
          ),
        ],
      ),
    );
  }

  String _displayRole(UserDto user) {
    if (user.roles.isEmpty) {
      return 'Korisnik';
    }
    return user.roles.join(' / ');
  }

  bool _isAdmin(UserDto user) {
    return user.roles.any((role) => role.toLowerCase().contains('admin'));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC), // Svijetla pozadina panela
      width: double.infinity,
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upravljanje korisnicima',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              RichText(
                text: const TextSpan(
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  children: [
                    TextSpan(text: 'Prijavljen: '),
                    TextSpan(
                      text: 'Admin Korisnik',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          Row(
            children: [
              Container(
                width: 320,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => _fetchUsers(searchTerm: value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Pretraži korisnike po imenu ili emailu...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: InputBorder.none,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _searchController.clear();
                              _fetchUsers(searchTerm: '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Gre�ka pri ucitavanju: $_error'))
                    : Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.015),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: SingleChildScrollView(
                          child: DataTable(
                            horizontalMargin: 24,
                            headingRowHeight: 55,
                            dataRowMaxHeight: 65,
                            dataRowMinHeight: 55,
                            headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'Ime i prezime',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 14),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Email',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 14),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Uloga',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 14),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Status',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 14),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Akcije',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 14),
                                ),
                              ),
                            ],
                            rows: _users.map((user) {
                              final isActive = !user.isBanned;
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      '${user.firstName} ${user.lastName}'.trim(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      user.email,
                                      style: const TextStyle(color: Color(0xFF64748B)),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      _displayRole(user),
                                      style: const TextStyle(color: Color(0xFF475569)),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isActive ? const Color(0xFFE6FFFA) : const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isActive ? 'Aktivan' : 'Blokiran',
                                        style: TextStyle(
                                          color: isActive ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!_isAdmin(user))
                                          OutlinedButton(
                                            onPressed: () {
                                              if (isActive) {
                                                _handleBanUser(user);
                                              } else {
                                                _handleUnbanUser(user);
                                              }
                                            },
                                            style: OutlinedButton.styleFrom(
                                              minimumSize: const Size(95, 30),
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              side: BorderSide(
                                                color: isActive ? const Color(0xFFFCA5A5) : const Color(0xFF60A5FA),
                                              ),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                            ),
                                            child: Text(
                                              isActive ? 'Ban' : 'Unban',
                                              style: TextStyle(
                                                color: isActive ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
