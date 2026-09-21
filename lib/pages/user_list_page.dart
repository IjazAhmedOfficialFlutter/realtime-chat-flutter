import 'package:flutter/material.dart';

import '../data/dummy_chat_data.dart';
import '../generated/l10n/app_localizations.dart';
import '../model/dummy_chat_models.dart';
import 'call_history_page.dart';
import 'chat_detail_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
  });

  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  String _search = '';

  List<DummyUser> get _filteredUsers {
    if (_search.trim().isEmpty) {
      return DummyChatData.users;
    }

    final query = _search.toLowerCase().trim();

    return DummyChatData.users.where((user) {
      return user.name.toLowerCase().contains(query) ||
          user.username.toLowerCase().contains(query);
    }).toList();
  }

  void _openChat(DummyUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailPage(user: user),
      ),
    );
  }

  void _startCall(DummyUser user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${user.name}...'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        title: Text(
          l10n.users,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: l10n.callHistory,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CallHistoryPage(),
                ),
              );
            },
            icon: const Icon(Icons.call),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Locale>(
                value: widget.locale,
                icon: const Icon(Icons.language),
                items: const [
                  DropdownMenuItem(
                    value: Locale('en'),
                    child: Text('EN'),
                  ),
                  DropdownMenuItem(
                    value: Locale('ur'),
                    child: Text('اردو'),
                  ),
                  DropdownMenuItem(
                    value: Locale('ar'),
                    child: Text('العربية'),
                  ),
                  DropdownMenuItem(
                    value: Locale('hi'),
                    child: Text('हिन्दी'),
                  ),
                  DropdownMenuItem(
                    value: Locale('bn'),
                    child: Text('বাংলা'),
                  ),
                ],
                onChanged: (locale) {
                  if (locale != null) {
                    widget.onLocaleChanged(locale);
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
              decoration: InputDecoration(
                hintText: l10n.searchUsers,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(
              child: Text(l10n.noUsersFound),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredUsers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];

                return _UserCard(
                  user: user,
                  onChat: () => _openChat(user),
                  onCall: () => _startCall(user),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final DummyUser user;
  final VoidCallback onChat;
  final VoidCallback onCall;

  const _UserCard({
    required this.user,
    required this.onChat,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onChat,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: const Color(0xFFDCFCE7),
                    child: Text(
                      user.name[0],
                      style: const TextStyle(
                        color: Color(0xFF166534),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (user.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 1,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.lastSeen,
                      style: TextStyle(
                        fontSize: 12,
                        color: user.isOnline
                            ? const Color(0xFF16A34A)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Chat',
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_outline),
              ),
              IconButton(
                tooltip: 'Call',
                onPressed: onCall,
                icon: const Icon(Icons.call_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}