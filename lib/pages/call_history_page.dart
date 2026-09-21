import 'package:flutter/material.dart';

import '../data/dummy_chat_data.dart';
import '../model/dummy_chat_models.dart';

class CallHistoryPage extends StatelessWidget {
  const CallHistoryPage({super.key});

  Color _callColor(DummyCallType type) {
    switch (type) {
      case DummyCallType.incoming:
        return const Color(0xFF16A34A);
      case DummyCallType.outgoing:
        return const Color(0xFF2563EB);
      case DummyCallType.missed:
        return const Color(0xFFDC2626);
    }
  }

  IconData _callIcon(DummyCallType type) {
    switch (type) {
      case DummyCallType.incoming:
        return Icons.call_received;
      case DummyCallType.outgoing:
        return Icons.call_made;
      case DummyCallType.missed:
        return Icons.call_missed;
    }
  }

  IconData _modeIcon(DummyCallMode mode) {
    switch (mode) {
      case DummyCallMode.audio:
        return Icons.call;
      case DummyCallMode.video:
        return Icons.videocam;
    }
  }

  String _callType(DummyCallType type) {
    switch (type) {
      case DummyCallType.incoming:
        return 'Incoming call';
      case DummyCallType.outgoing:
        return 'Outgoing call';
      case DummyCallType.missed:
        return 'Missed call';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        title: const Text(
          'Call History',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: DummyChatData.callHistory.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final call = DummyChatData.callHistory[index];
          final color = _callColor(call.type);

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      call.userName[0],
                      style: const TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          call.userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              _callIcon(call.type),
                              size: 15,
                              color: color,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _callType(call.type),
                              style: TextStyle(
                                fontSize: 12,
                                color: color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _modeIcon(call.mode),
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${call.time} • ${call.duration}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Calling ${call.userName}...'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.call_outlined),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}