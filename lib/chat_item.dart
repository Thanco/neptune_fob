class ChatItem extends Comparable<ChatItem> {
  final int itemIndex;
  final String userName;
  final String type;
  final dynamic content;

  ChatItem(
    this.itemIndex,
    this.userName,
    this.type,
    this.content,
  );

  ChatItem.fromJson(Map<String, dynamic> json)
      : itemIndex = json['itemIndex'],
        userName = json['userName'],
        content = json['content'],
        type = json['type'];

  Map<String, dynamic> toJson() => {
        'itemIndex': itemIndex,
        'userName': userName,
        'content': content,
        'type': type,
      };

  @override
  int compareTo(ChatItem other) {
    return itemIndex - other.itemIndex;
  }
}
