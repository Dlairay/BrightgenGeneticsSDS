class ChatMessageModel {
  final String id;
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final String? attachmentUrl;
  final AttachmentType? attachmentType;
  
  ChatMessageModel({
    required this.id,
    required this.text,
    required this.isBot,
    required this.timestamp,
    this.attachmentUrl,
    this.attachmentType,
  });
  
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      text: json['text'],
      isBot: json['isBot'],
      timestamp: DateTime.parse(json['timestamp']),
      attachmentUrl: json['attachmentUrl'],
      attachmentType: json['attachmentType'] != null 
          ? AttachmentType.values.firstWhere(
              (e) => e.toString() == json['attachmentType'],
            )
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isBot': isBot,
      'timestamp': timestamp.toIso8601String(),
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType?.toString(),
    };
  }
}

enum AttachmentType { image, document, audio }