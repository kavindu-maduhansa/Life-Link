import 'package:flutter/material.dart';

class ChatMessage {
  final String text;
  final bool isMe; // true = coordinator, false = donor
  final String? meta; // e.g. "D-1042 • Available now"

  const ChatMessage({
    required this.text,
    required this.isMe,
    this.meta,
  });
}

class OrganisationProtectedConversationScreen extends StatefulWidget {
  /// Donor shown in the header title (e.g. "D-1042")
  final String donorId;

  const OrganisationProtectedConversationScreen({
    super.key,
    this.donorId = 'D-1042',
  });

  @override
  State<OrganisationProtectedConversationScreen> createState() =>
      _OrganisationProtectedConversationScreenState();
}

class _OrganisationProtectedConversationScreenState
    extends State<OrganisationProtectedConversationScreen> {
  // ============================================================
  // DESIGN COLORS (same as the other coordinator screens)
  // ============================================================

  static const Color backgroundColor = Color(0xFFFAF7F6);
  static const Color whiteColor = Colors.white;
  static const Color primaryMaroon = Color(0xFF971B3E);
  static const Color mainText = Color(0xFF182131);
  static const Color secondaryText = Color(0xFF68758A);
  static const Color pinkCard = Color(0xFFFCE8EC);
  static const Color borderColor = Color(0xFFE6DADD);
  static const Color successGreen = Color(0xFF1E8A4C);
  static const Color privacyBg = Color(0xFFE6F5EE);
  static const Color privacyBorder = Color(0xFFCFE6DA);
  static const Color bubbleOrangeBg = Color(0xFFFCEFDC);
  static const Color bubbleOrangeBorder = Color(0xFFC77A1A);
  static const Color sendButtonColor = Color(0xFF0F1B3A);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // TODO: replace with real data (Firestore) later
  final List<ChatMessage> _messages = [
    const ChatMessage(
      text: 'Hello! A verified A+ emergency request\nis nearby. Are you available to donate?',
      isMe: true,
    ),
    const ChatMessage(
      text: 'Hi, yes. I can donate today.',
      isMe: false,
      meta: 'D-1042 • Available now',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isMe: true));
    });
    _controller.clear();

    // TODO: save message to Firestore

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    _buildPrivacyBanner(),
                    const SizedBox(height: 24),
                    for (final m in _messages) _buildMessageBubble(m),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Request details'),
                    const SizedBox(height: 12),
                    _buildRequestDetailsCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 13, 17, 14),
      decoration: const BoxDecoration(
        color: whiteColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40,
              height: 36,
              decoration: BoxDecoration(
                color: pinkCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 26,
                color: primaryMaroon,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message ${widget.donorId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: mainText,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'A+ emergency request • protected',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRIVACY BANNER
  // ============================================================

  Widget _buildPrivacyBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: privacyBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: privacyBorder),
        ),
        child: const Text(
          'Phone numbers are hidden for privacy.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: secondaryText),
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================

  Widget _buildMessageBubble(ChatMessage message) {
    // Matches the Figma layout: coordinator bubble on the left,
    // donor bubble pushed to the right.
    final bool isMe = message.isMe;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMe ? 52 : 100,
        0,
        isMe ? 52 : 52,
        16,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: isMe ? bubbleOrangeBg : whiteColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: bubbleOrangeBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  fontSize: isMe ? 13 : 14,
                  color: mainText,
                  height: 1.6,
                ),
              ),
              if (message.meta != null) ...[
                const SizedBox(height: 2),
                Text(
                  message.meta!,
                  style: const TextStyle(fontSize: 11, color: secondaryText),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REQUEST DETAILS
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: mainText,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _buildRequestDetailsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'A+ • 4 units',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: mainText,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Text(
                    'Verified',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: successGreen,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              'District General Hospital',
              style: TextStyle(fontSize: 12, color: secondaryText),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE INPUT
  // ============================================================

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: whiteColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    style: const TextStyle(fontSize: 13, color: mainText),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(fontSize: 13, color: secondaryText),
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 72,
                height: 48,
                child: ElevatedButton(
                  onPressed: _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sendButtonColor,
                    foregroundColor: whiteColor,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Send',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              'Protected in-app communication • phone number not shared',
              style: TextStyle(fontSize: 11, color: secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}