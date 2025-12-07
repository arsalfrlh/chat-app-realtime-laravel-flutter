import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:toko/models/chat.dart';

class ApiService {
  final String baseUrl = "http://10.0.2.2:8000/api";

  Future<List<Chat>> getAllChat()async{
    try{
      final response = await http.get(Uri.parse("$baseUrl/chat"));
      if(response.statusCode == 200){
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((item) => Chat.fromJson(item)).toList();
      }else{
        throw Exception(json.decode(response.body));
      }
    }catch(e){
      throw Exception(e);
    }
  }

  Future<Map<String, dynamic>> sendChat(String message)async{
    try{
      final response = await http.post(Uri.parse("$baseUrl/chat/tambah"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "message": message,
        "device": "mobile"
      }));

      if(response.statusCode == 200){
        return json.decode(response.body);
      }else{
        return{
          "success": false,
          "message": json.decode(response.body)
        };
      }
    }catch(e){
      return{
        "success": false,
        "message": e
      };
    }
  }

  Future<Map<String, dynamic>> updateChat(int id, String message)async{
    try{
      final response = await http.put(Uri.parse("$baseUrl/chat/update"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "id": id,
        "message": message
      }));

      if(response.statusCode == 200){
        return json.decode(response.body);
      }else{
        return{
          "success": false,
          "message": json.decode(response.body)
        };
      }
    }catch(e){
      return{
        "success": false,
        "message": e
      };
    }
  }

  Future<void> deleteChat(int id)async{
    try{
      await http.delete(Uri.parse("$baseUrl/chat/hapus/$id"));
    }catch(e){
      throw Exception(e);
    }
  }
}