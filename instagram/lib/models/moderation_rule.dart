enum ViolationType { scam, profanity, linkSpam }

class ModerationRule {
  final ViolationType type;
  final RegExp pattern;
  final String warningMessage;

  ModerationRule(this.type, this.pattern, this.warningMessage);
}