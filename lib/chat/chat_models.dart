class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });

  final String text;
  final bool isUser;
  final bool isError;
}

class AgentStep {
  const AgentStep(this.text, {this.isError = false});

  final String text;
  final bool isError;
}
