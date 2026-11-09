import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String orderNumber;

  const ChatScreen({
    super.key,
    required this.orderNumber,
  });

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _sending = false;
  bool _initializingChat = true;

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
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      final user =
          FirebaseAuth.instance.currentUser;

      if (user != null) {
        await _chatRef.set(
          {
            'orderNumber':
                widget.orderNumber,
            'guestUid': user.uid,
          },
          SetOptions(merge: true),
        );
      }
    } catch (_) {
      // Сообщения всё равно можно отправить,
      // если соединение восстановится позже.
    }

    if (mounted) {
      setState(() {
        _initializingChat = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text =
        _controller.text.trim();

    if (text.isEmpty || _sending) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception(
          'Пользователь не авторизован.',
        );
      }

      final messageRef =
          _messages.doc();

      final batch =
          _firestore.batch();

      batch.set(
        _chatRef,
        {
          'orderNumber':
              widget.orderNumber,
          'guestUid':
              user.uid,
          'status': 'new',
          'unreadForStaff': true,
          'lastMessage': text,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        messageRef,
        {
          'text': text,
          'isGuest': true,
          'guestUid': user.uid,
          'createdAt':
              FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      _controller.clear();

      if (mounted) {
        FocusScope.of(context)
            .unfocus();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Ошибка отправки:\n$e',
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

  Future<void> _sendQuickMessage(
    String text,
  ) async {
    _controller.text = text;
    await _sendMessage();
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
      backgroundColor:
          const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0D0D0D),
        elevation: 0,
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Чат с официантом',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
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
        iconTheme:
            const IconThemeData(
          color: Color(0xFFD4AF37),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _initializingChat
                ? const Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          Color(0xFFD4AF37),
                    ),
                  )
                : StreamBuilder<
                    QuerySnapshot<
                        Map<String,
                            dynamic>>>(
                    stream: _messages
                        .orderBy(
                          'createdAt',
                        )
                        .snapshots(),
                    builder: (
                      context,
                      snapshot,
                    ) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .all(20),
                            child: Text(
                              'Ошибка загрузки сообщений:\n\n'
                              '${snapshot.error}',
                              textAlign:
                                  TextAlign.center,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.redAccent,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }

                      if (snapshot
                              .connectionState ==
                          ConnectionState
                              .waiting) {
                        return const Center(
                          child:
                              CircularProgressIndicator(
                            color: Color(
                              0xFFD4AF37,
                            ),
                          ),
                        );
                      }

                      final messages =
                          snapshot.data?.docs ??
                              [];

                      if (messages.isEmpty) {
                        return const Center(
                          child: Text(
                            'Начните диалог '
                            'с официантом',
                            style: TextStyle(
                              color:
                                  Colors.white54,
                              fontSize: 15,
                            ),
                          ),
                        );
                      }

                      WidgetsBinding.instance
                          .addPostFrameCallback(
                        (_) {
                          if (_scrollController
                              .hasClients) {
                            _scrollController
                                .jumpTo(
                              _scrollController
                                  .position
                                  .maxScrollExtent,
                            );
                          }
                        },
                      );

                      return ListView.builder(
                        controller:
                            _scrollController,
                        padding:
                            const EdgeInsets.all(
                          16,
                        ),
                        itemCount:
                            messages.length,
                        itemBuilder: (
                          context,
                          index,
                        ) {
                          final data =
                              messages[index]
                                  .data();

                          final text =
                              data['text']
                                      as String? ??
                                  '';

                          final isGuest =
                              data['isGuest'] ==
                                  true;

                          return Align(
                            alignment: isGuest
                                ? Alignment
                                    .centerRight
                                : Alignment
                                    .centerLeft,
                            child:
                                Container(
                              constraints:
                                  const BoxConstraints(
                                maxWidth: 300,
                              ),
                              margin:
                                  const EdgeInsets
                                      .only(
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
                                        0xFFD4AF37)
                                    : const Color(
                                        0xFF222222),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  16,
                                ),
                              ),
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: isGuest
                                      ? Colors
                                          .black
                                      : Colors
                                          .white,
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

          SingleChildScrollView(
            scrollDirection:
                Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Row(
              children: [
                _QuickMessage(
                  text:
                      'Позвать официанта',
                  onTap: () {
                    _sendQuickMessage(
                      'Позвать официанта',
                    );
                  },
                ),
                _QuickMessage(
                  text:
                      'Где мой заказ?',
                  onTap: () {
                    _sendQuickMessage(
                      'Где мой заказ?',
                    );
                  },
                ),
                _QuickMessage(
                  text:
                      'Можно меню?',
                  onTap: () {
                    _sendQuickMessage(
                      'Можно меню?',
                    );
                  },
                ),
              ],
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
                      controller:
                          _controller,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                      ),
                      textInputAction:
                          TextInputAction
                              .send,
                      onSubmitted: (_) {
                        _sendMessage();
                      },
                      decoration:
                          InputDecoration(
                        hintText:
                            'Напишите сообщение...',
                        hintStyle:
                            const TextStyle(
                          color:
                              Colors.white38,
                        ),
                        filled: true,
                        fillColor:
                            const Color(
                          0xFF191919,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
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
                  const SizedBox(
                    width: 8,
                  ),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: IconButton(
                      onPressed:
                          _sending
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
                                strokeWidth:
                                    2,
                                color:
                                    Colors.black,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color:
                                  Colors.black,
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

class _QuickMessage
    extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _QuickMessage({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        right: 8,
      ),
      child: OutlinedButton(
        onPressed: onTap,
        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              const Color(0xFFD4AF37),
          side: const BorderSide(
            color: Color(0xFFD4AF37),
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),
        ),
        child: Text(text),
      ),
    );
  }
}
