import '../model/dummy_chat_models.dart';

class DummyChatData {
  static const currentUserId = 1;

  static const users = [
    DummyUser(
      id: 2,
      name: 'Ahmed Khan',
      username: '@ahmed',
      isOnline: true,
      lastSeen: 'Online',
      unreadCount: 2,
    ),
    DummyUser(
      id: 3,
      name: 'Sarah Ali',
      username: '@sarah',
      isOnline: true,
      lastSeen: 'Online',
    ),
    DummyUser(
      id: 4,
      name: 'Usman Malik',
      username: '@usman',
      isOnline: false,
      lastSeen: 'Last seen 10 min ago',
      unreadCount: 5,
    ),
    DummyUser(
      id: 5,
      name: 'Ayesha Noor',
      username: '@ayesha',
      isOnline: true,
      lastSeen: 'Online',
    ),
    DummyUser(
      id: 6,
      name: 'Hamza Sheikh',
      username: '@hamza',
      isOnline: false,
      lastSeen: 'Last seen yesterday',
    ),
    DummyUser(
      id: 7,
      name: 'Fatima Zahra',
      username: '@fatima',
      isOnline: true,
      lastSeen: 'Online',
      unreadCount: 1,
    ),
  ];

  static final messages = <int, List<DummyMessage>>{
    2: const [
      DummyMessage(
        id: 1,
        senderId: 2,
        message: 'Hey! How are you?',
        time: '10:30 AM',
        isRead: true,
      ),
      DummyMessage(
        id: 2,
        senderId: currentUserId,
        message: 'I am good. How about you?',
        time: '10:31 AM',
        isRead: true,
      ),
      DummyMessage(
        id: 3,
        senderId: 2,
        message: 'I am doing great!',
        time: '10:32 AM',
        isRead: true,
      ),
      DummyMessage(
        id: 4,
        senderId: currentUserId,
        message: 'Are you available for a call?',
        time: '10:34 AM',
        isRead: true,
      ),
      DummyMessage(
        id: 5,
        senderId: 2,
        message: 'Yes, give me a few minutes.',
        time: '10:35 AM',
        isRead: true,
      ),
    ],
    3: const [
      DummyMessage(
        id: 6,
        senderId: 3,
        message: 'Hello! Did you check the latest update?',
        time: '09:42 AM',
        isRead: true,
      ),
      DummyMessage(
        id: 7,
        senderId: currentUserId,
        message: 'Yes, everything looks good.',
        time: '09:45 AM',
        isRead: true,
      ),
    ],
    4: const [
      DummyMessage(
        id: 8,
        senderId: 4,
        message: 'Can you send me the document?',
        time: 'Yesterday',
        isRead: false,
      ),
      DummyMessage(
        id: 9,
        senderId: currentUserId,
        message: 'Sure, I will send it shortly.',
        time: 'Yesterday',
        isRead: true,
      ),
    ],
    5: const [
      DummyMessage(
        id: 10,
        senderId: currentUserId,
        message: 'Good morning!',
        time: 'Yesterday',
        isRead: true,
      ),
    ],
    6: const [
      DummyMessage(
        id: 11,
        senderId: 6,
        message: 'Let me know when you are free.',
        time: 'Monday',
        isRead: true,
      ),
    ],
    7: const [
      DummyMessage(
        id: 12,
        senderId: 7,
        message: 'Thank you!',
        time: 'Monday',
        isRead: true,
      ),
    ],
  };

  static const callHistory = [
    DummyCall(
      id: 1,
      userName: 'Ahmed Khan',
      type: DummyCallType.outgoing,
      mode: DummyCallMode.audio,
      time: 'Today, 10:15 AM',
      duration: '04:32',
    ),
    DummyCall(
      id: 2,
      userName: 'Sarah Ali',
      type: DummyCallType.incoming,
      mode: DummyCallMode.video,
      time: 'Today, 09:20 AM',
      duration: '12:45',
    ),
    DummyCall(
      id: 3,
      userName: 'Usman Malik',
      type: DummyCallType.missed,
      mode: DummyCallMode.audio,
      time: 'Yesterday, 08:40 PM',
      duration: '00:00',
    ),
    DummyCall(
      id: 4,
      userName: 'Ayesha Noor',
      type: DummyCallType.outgoing,
      mode: DummyCallMode.video,
      time: 'Yesterday, 06:15 PM',
      duration: '08:21',
    ),
    DummyCall(
      id: 5,
      userName: 'Hamza Sheikh',
      type: DummyCallType.incoming,
      mode: DummyCallMode.audio,
      time: 'Monday, 04:10 PM',
      duration: '02:18',
    ),
  ];
}