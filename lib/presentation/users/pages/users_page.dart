
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth_services.dart';
import '../../../core/di/injection.dart';
import '../../../data/services/firebase_messaging_service.dart';
import '../../../model/user_model.dart';
import '../cubit/users_cubit.dart';
import '../cubit/users_state.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  UsersCubit? _usersCubit;
  final _firebaseMessagingService =
  locator<FirebaseMessagingService>();


  String _search = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _firebaseMessagingService.onMessageReceived =
        _handleFcmMessage;
  }
  Future<void> _handleFcmMessage(
      RemoteMessage message,
      ) async {
    final type = message.data['type']?.toString();

    if (type != 'chat_message') {
      return;
    }

    final cubit = _usersCubit;

    if (cubit == null || !mounted) {
      return;
    }

    await cubit.loadUsers(  showLoading: false,);
  }
  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    if (state == AppLifecycleState.resumed) {
      _usersCubit?.loadUsers(  showLoading: false,);

    }
  }

  Future<void> _logout() async {
    await locator<AuthService>().logout();

    if (!mounted) {
      return;
    }

    context.go('/login');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _firebaseMessagingService.onMessageReceived = null;

    _searchController.dispose();
    _usersCubit = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = locator<UsersCubit>();

        _usersCubit = cubit;
        return cubit..loadUsers();
      },
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);

          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'People',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Logout',
                  onPressed: _logout,
                  icon: const Icon(
                    Icons.logout_rounded,
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    12,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _search = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search people',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                      ),
                      suffixIcon: _search.isEmpty
                          ? null
                          : IconButton(
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _search = '';
                          });
                        },
                        icon: const Icon(
                          Icons.clear_rounded,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: BlocBuilder<UsersCubit, UsersState>(
                    builder: (context, state) {
                      if (state.status == UsersStatus.loading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (state.status == UsersStatus.failure) {
                        return _buildErrorState(
                          theme,
                          state.errorMessage,
                          context,
                        );
                      }

                      final query =
                      _search.trim().toLowerCase();

                      final users =
                      state.users.where((user) {
                        return user.name
                            .toLowerCase()
                            .contains(query) ||
                            user.email
                                .toLowerCase()
                                .contains(query);
                      }).toList();

                      if (users.isEmpty) {
                        return _buildEmptyState(theme);
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        itemCount: users.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final user = users[index];

                          return _UserTile(
                            user: user,
                            onTap: () async {
                              await context.push(
                                '/chat/${user.id}',
                                extra: user,
                              );

                              if (!mounted) {
                                return;
                              }

                              await _usersCubit?.loadUsers(  showLoading: false,);

                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(
      ThemeData theme,
      String? message,
      BuildContext context,
      ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load people',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Something went wrong.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                context.read<UsersCubit>().loadUsers();
              },
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No people found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _UserTile({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 27,
                    child: Text(
                      user.name.isEmpty
                          ? '?'
                          : user.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (user.lastMessageAt != null)
                          Text(
                            _formatMessageTime(
                              user.lastMessageAt!,
                            ),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(
                              color:
                              colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.lastMessage?.isNotEmpty == true
                                ? user.lastMessage!
                                : user.isOnline
                                ? 'Online'
                                : user.email,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(
                              color: user.lastMessage
                                  ?.isNotEmpty ==
                                  true
                                  ? colors
                                  .onSurfaceVariant
                                  : user.isOnline
                                  ? Colors.green
                                  : colors
                                  .onSurfaceVariant,
                              fontWeight:
                              user.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (user.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          _UnreadBadge(
                            count: user.unreadCount,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();

    final difference = now.difference(local);

    if (difference.inDays == 0 &&
        local.day == now.day) {
      final hour = local.hour > 12
          ? local.hour - 12
          : local.hour == 0
          ? 12
          : local.hour;

      final minute =
      local.minute.toString().padLeft(2, '0');

      final period = local.hour >= 12 ? 'PM' : 'AM';

      return '$hour:$minute $period';
    }

    if (difference.inDays == 1 ||
        (difference.inHours < 48 &&
            local.day != now.day)) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      const days = [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ];

      return days[local.weekday - 1];
    }

    return '${local.day}/${local.month}/${local.year}';
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(
        minWidth: 22,
        minHeight: 22,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
      ),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          color: colors.onPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

