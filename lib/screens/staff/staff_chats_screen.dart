import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StaffChatsScreen extends StatelessWidget {
  const StaffChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatsQuery = FirebaseFirestore.instance
        .collection('chats')
        .orderBy('updatedAt', descending: true);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFFD4AF37),
        ),
        title: const Text(
          'Панель официанта',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: chatsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Ошибка загрузки чатов:\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD4AF37),
              ),
            );
          }

          final chats = snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFFD4AF37),
                    size: 55,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Чатов пока нет',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final data = chats[index].data();

              final orderNumber =
                  data['orderNumber'] as String? ??
                      chats[index].id;

              final lastMessage =
                  data['lastMessage'] as String? ??
                      'Нет сообщений';

              final status =
                  data['status'] as String? ?? 'new';

              final unreadForStaff =
                  data['unreadForStaff'] == true;

              final updatedAt =
                  data['updatedAt'] as Timestamp?;

              return _ChatCard(
                orderNumber: orderNumber,
                lastMessage: lastMessage,
                status: status,
                unreadForStaff: unreadForStaff,
                updatedAt: updatedAt,
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  final String orderNumber;
  final String lastMessage;
  final String status;
  final bool unreadForStaff;
  final Timestamp? updatedAt;

  const _ChatCard({
    required this.orderNumber,
    required this.lastMessage,
    required this.status,
    required this.unreadForStaff,
    required this.updatedAt,
  });

  String get statusText {
    switch (status) {
      case 'new':
        return 'Новое';

      case 'in_progress':
        return 'В работе';

      case 'closed':
        return 'Закрыто';

      default:
        return 'Новое';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'new':
        return const Color(0xFFD4AF37);

      case 'in_progress':
        return Colors.orange;

      case 'closed':
        return Colors.green;

      default:
        return const Color(0xFFD4AF37);
    }
  }

  String get timeText {
    if (updatedAt == null) {
      return '';
    }

    final date = updatedAt!.toDate();

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unreadForStaff
              ? const Color(0xFFD4AF37)
              : const Color(0xFF242424),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StaffChatScreen(
                  orderNumber: orderNumber,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFD4AF37)
                            .withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    color: Color(0xFFD4AF37),
                    size: 29,
                  ),
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
                              'Заказ $orderNumber',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                          if (timeText.isNotEmpty)
                            Text(
                              timeText,
                              style:
                                  const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lastMessage,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unreadForStaff
                              ? Colors.white
                              : Colors.white54,
                          fontSize: 14,
                          fontWeight: unreadForStaff
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  statusColor
                                      .withValues(
                                alpha: 0.12,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                              border: Border.all(
                                color:
                                    statusColor
                                        .withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                          if (unreadForStaff) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.circle,
                              color: Color(0xFFD4AF37),
                              size: 8,
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Новое сообщение',
                              style: TextStyle(
                                color:
                                    Color(0xFFD4AF37),
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StaffChatScreen extends StatefulWidget {
  final String orderNumber;

  const StaffChatScreen({
    super.key,
    required this.orderNumber,
  });

  @override
  State<StaffChatScreen> createState() =>
      _StaffChatScreenState();
}

class _StaffChatScreenState
    extends State<StaffChatScreen> {
  final TextEditingController _controller =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _sending = false;

  CollectionReference<Map<String, dynamic>>
      get _messages {
    return _firestore
        .collection('chats')
        .doc(widget.orderNumber)
        .collection('messages');
  }

  DocumentReference<Map<String, dynamic>>
      get _chatRef {
    return _firestore
        .collection('chats')
        .doc(widget.orderNumber);
  }

  @override
  void initState() {
    super.initState();
    _setInProgress();
  }

  Future<void> _setInProgress() async {
    try {
      await _chatRef.set(
        {
          'orderNumber': widget.orderNumber,
          'status': 'in_progress',
          'unreadForStaff': false,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _sending) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      final messageRef = _messages.doc();

      final batch = _firestore.batch();

      batch.set(
        messageRef,
        {
          'text': text,
          'isGuest': false,
          'createdAt':
              FieldValue.serverTimestamp(),
        },
      );

      batch.set(
        _chatRef,
        {
          'orderNumber': widget.orderNumber,
          'status': 'in_progress',
          'unreadForStaff': false,
          'lastMessage': text,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      _controller.clear();

      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ошибка отправки: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _closeChat() async {
    try {
      await _chatRef.set(
        {
          'status': 'closed',
          'unreadForStaff': false,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Чат закрыт',
          ),
          backgroundColor: Color(0xFF1A1A1A),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ошибка: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFFD4AF37),
        ),
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Чат с гостем',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Заказ ${widget.orderNumber}',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _closeChat,
            tooltip: 'Закрыть чат',
            icon: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFFD4AF37),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream: _messages
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(20),
                      child: Text(
                        'Ошибка загрузки сообщений:\n\n'
                        '${snapshot.error}',
                        textAlign:
                            TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(
                      color: Color(0xFFD4AF37),
                    ),
                  );
                }

                final messages =
                    snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Сообщений пока нет',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 15,
                      ),
                    ),
                  );
                }

                WidgetsBinding.instance
                    .addPostFrameCallback((_) {
                  if (_scrollController
                      .hasClients) {
                    _scrollController.animateTo(
                      _scrollController
                          .position.maxScrollExtent,
                      duration:
                          const Duration(
                        milliseconds: 200,
                      ),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller:
                      _scrollController,
                  padding:
                      const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (
                    context,
                    index,
                  ) {
                    final data =
                        messages[index].data();

                    final text =
                        data['text']
                                as String? ??
                            '';

                    final isGuest =
                        data['isGuest'] == true;

                    return Align(
                      alignment: isGuest
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        constraints:
                            const BoxConstraints(
                          maxWidth: 300,
                        ),
                        margin:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 15,
                          vertical: 11,
                        ),
                        decoration:
                            BoxDecoration(
                          color: isGuest
                              ? const Color(
                                  0xFF222222,
                                )
                              : const Color(
                                  0xFFD4AF37,
                                ),
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: isGuest
                                ? Colors.white
                                : Colors.black,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                12,
                5,
                12,
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                      textInputAction:
                          TextInputAction.send,
                      onSubmitted: (_) {
                        _sendMessage();
                      },
                      decoration:
                          InputDecoration(
                        hintText:
                            'Ответить гостю...',
                        hintStyle:
                            const TextStyle(
                          color: Colors.white38,
                        ),
                        filled: true,
                        fillColor:
                            const Color(0xFF191919),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: IconButton(
                      onPressed: _sending
                          ? null
                          : _sendMessage,
                      style:
                          IconButton.styleFrom(
                        backgroundColor:
                            const Color(
                          0xFFD4AF37,
                        ),
                      ),
                      icon: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.black,
                            ),
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