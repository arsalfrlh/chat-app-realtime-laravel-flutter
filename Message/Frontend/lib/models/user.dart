class User {
  final int id;
  final String name;
  final String email;
  final DateTime updateAt;

  User({required this.id, required this.name, required this.email, required this.updateAt});
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      updateAt: DateTime.parse(json['updated_at'])
    );
  }
}
