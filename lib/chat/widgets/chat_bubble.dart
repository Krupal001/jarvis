import 'package:flutter/material.dart';
import 'package:flutter_gemma_demo/chat/widgets/typing_dots.dart';
import 'package:flutter_gemma_demo/ui/app_theme.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.isError = false,
    this.isStreaming = false,
  });

  final String text;
  final bool isUser;
  final bool isError;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final isAI = !isUser && !isError;

    final bg = isError
        ? AppColors.red.withValues(alpha: 0.06)
        : isUser
        ? AppColors.primary
        : Colors.transparent;

    final fg = isError
        ? AppColors.red
        : isUser
        ? Colors.white
        : AppColors.textPrimary;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        padding: isAI
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: text.isEmpty && isStreaming
            ? const TypingDots()
            : isAI
            ? GptMarkdown(
                text,
                isStreaming: isStreaming,
                onLinkTap: (url, title) =>
                    launchUrl(Uri.parse(url)), // needs url_launcher
                styleSheet: GptMarkdownStyleSheet(
                  inlineCode: InlineCodeStyle(
                    fontFamily: 'monospace',
                    backgroundColor: AppColors.bgSoft,
                    borderRadius: const Radius.circular(4),
                  ),
                  codeBlock: CodeBlockStyle(
                    borderRadius: const Radius.circular(12),
                    showCopyButton: true,
                  ),
                  blockQuote: BlockQuoteStyle(
                    barWidth: 3,
                    barColor: AppColors.primary,
                  ),
                ),
              )
            : SelectableText(
                text,
                style: AppText.body.copyWith(
                  color: fg,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
      ),
    );
  }
}
