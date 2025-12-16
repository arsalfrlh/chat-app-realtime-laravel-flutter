import 'package:toko/models/user.dart';

class Chat {
  final int id;
  final String message;
  final String? gambar;
  final String status;
  final DateTime createAt;
  final User user;

  Chat({required this.id, required this.message, this.gambar, required this.status, required this.createAt, required this.user});
  factory Chat.fromJson(Map<String, dynamic> json){
    return Chat(
      id: json['id'],
      message: json['message'],
      gambar: json['gambar'],
      status: json['status'],
      createAt: DateTime.parse(json['created_at']),
      user: User.fromJson(json['user'])
    );
  }
}
