class Chat{
  final int id;
  final String device;
  final String message;
  final DateTime createAt;

  Chat({required this.id, required this.device, required this.message, required this.createAt});
  factory Chat.fromJson(Map<String, dynamic> json){
    return Chat(
      id: json['id'],
      device: json['device'],
      message: json['message'],
      createAt: DateTime.parse(json['created_at'])
    );
  }
}