import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/admin_dto.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/models/requests/admin_user_search_request.dart';
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
  Timer? _debounce;

  // Paginacijske varijable
  List<UserDto> _users = [];
  int _currentPage = 1;
  int _pageSize = 5;
  int _totalCount = 0;
  bool _isLoading = true;
  String? _error;

    static const int _flexName = 3;
  static const int _flexEmail = 3;
  static const int _flexRole = 2;
  static const int _flexStatus = 2;
  static const int _flexActions = 2;



  @override
  void initState() {
    super.initState();
    _adminService = AdminService(DioClient.getDio());
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Prepravljena metoda koja podržava promjenu stranica i reset na pretragu
  Future<void> _fetchUsers({String searchTerm = '', bool isNewSearch = false}) async {
    if (isNewSearch) {
      _currentPage = 1; // Resetujemo na prvu stranicu ako je nova pretraga
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final request = AdminUserSearchRequest(
        searchTerm: searchTerm.isEmpty ? null : searchTerm,
        page: _currentPage,
        pageSize: _pageSize,
      );

      final pagedResult = await _adminService.search(request);
      if (!mounted) return;

      setState(() {
        _users = pagedResult.result;
        _totalCount = pagedResult.totalCount;
        _currentPage = pagedResult.page;
        _pageSize = pagedResult.pageSize;
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

  // Debounce sprečava DDOS-ovanje sopstvenog backenda dok korisnik kuca
  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchUsers(searchTerm: value.trim(), isNewSearch: true);
    });
  }

  Future<void> _handleBanUser(UserDto user) async {
    final reason = await _showBanReasonDialog();
    if (reason == null || reason.isEmpty) return;

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
            child: const Text('Otkaži'),
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
    if (user.roles.isEmpty) return 'Korisnik';
    return user.roles.join(' / ');
  }

  bool _isAdmin(UserDto user) {
    return user.roles.any((role) => role.toLowerCase().contains('admin'));
  }
Widget _headerCell(String text, int flex, {TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _dataCell(Widget child, int flex, {TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: align == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int startItem = _users.isEmpty ? 0 : (_currentPage - 1) * _pageSize + 1;
    final int endItem =
        (_currentPage * _pageSize) > _totalCount ? _totalCount : (_currentPage * _pageSize);

    return Container(
      color: const Color(0xFFF8FAFC),
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
                  onChanged: _onSearchChanged,
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
                              _fetchUsers(searchTerm: '', isNewSearch: true);
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
            child: _isLoading && _users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Greška pri učitavanju: $_error'))
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
                        child: Column(
                          children: [
                            // --- Header red (fiksiran, razvučen preko cijele širine) ---
                            Container(
                              height: 55,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                children: [
                                  _headerCell('Ime i prezime', _flexName),
                                  _headerCell('Email', _flexEmail),
                                  _headerCell('Uloga', _flexRole),
                                  _headerCell('Status', _flexStatus),
                                  _headerCell('Akcije', _flexActions, align: TextAlign.right),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),

                            // --- Redovi podataka, razvučeni preko cijele širine ---
                            Expanded(
                              child: _users.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Nema pronađenih korisnika.',
                                        style: TextStyle(color: Color(0xFF64748B)),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: _users.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                      itemBuilder: (context, index) {
                                        final user = _users[index];
                                        final isActive = !user.isBanned;

                                        return Container(
                                          height: 65,
                                          padding: const EdgeInsets.symmetric(horizontal: 24),
                                          child: Row(
                                            children: [
                                              _dataCell(
                                                Text(
                                                  '${user.firstName} ${user.lastName}'.trim(),
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                                _flexName,
                                              ),
                                              _dataCell(
                                                Text(
                                                  user.email,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(color: Color(0xFF64748B)),
                                                ),
                                                _flexEmail,
                                              ),
                                              _dataCell(
                                                Text(
                                                  _displayRole(user),
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(color: Color(0xFF475569)),
                                                ),
                                                _flexRole,
                                              ),
                                              _dataCell(
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 10, vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: isActive
                                                        ? const Color(0xFFE6FFFA)
                                                        : const Color(0xFFFEE2E2),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    isActive ? 'Aktivan' : 'Blokiran',
                                                    style: TextStyle(
                                                      color: isActive
                                                          ? const Color(0xFF047857)
                                                          : const Color(0xFFB91C1C),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                _flexStatus,
                                              ),
                                              _dataCell(
                                                !_isAdmin(user)
                                                    ? OutlinedButton(
                                                        onPressed: () => isActive
                                                            ? _handleBanUser(user)
                                                            : _handleUnbanUser(user),
                                                        style: OutlinedButton.styleFrom(
                                                          minimumSize: const Size(95, 30),
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 12),
                                                          side: BorderSide(
                                                            color: isActive
                                                                ? const Color(0xFFFCA5A5)
                                                                : const Color(0xFF60A5FA),
                                                          ),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(4)),
                                                        ),
                                                        child: Text(
                                                          isActive ? 'Ban' : 'Unban',
                                                          style: TextStyle(
                                                            color: isActive
                                                                ? const Color(0xFFEF4444)
                                                                : const Color(0xFF2563EB),
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      )
                                                    : const SizedBox.shrink(),
                                                _flexActions,
                                                align: TextAlign.right,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),

                            // --- Traka za paginaciju ---
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Prikazano $startItem - $endItem od ukupno $_totalCount korisnika',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left),
                                        onPressed: _currentPage > 1 && !_isLoading
                                            ? () {
                                                setState(() => _currentPage--);
                                                _fetchUsers(searchTerm: _searchController.text);
                                              }
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Stranica $_currentPage',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right),
                                        onPressed: (endItem < _totalCount) && !_isLoading
                                            ? () {
                                                setState(() => _currentPage++);
                                                _fetchUsers(searchTerm: _searchController.text);
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}