import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toko/models/chat.dart';
import 'package:toko/models/user.dart';

class ApiService {
  final String baseUrl = "http://10.0.2.2:8000/api";

  Future<Map<String, dynamic>> login(String email, String password)async{
    try{
      final response = await http.post(Uri.parse("$baseUrl/login"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "email": email,
        "password": password
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

  Future<Map<String, dynamic>> register(String name, String email, String password)async{
    try{
      final response = await http.post(Uri.parse("$baseUrl/register"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "name": name,
        "email": email,
        "password": password
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

  Future<Map<String, dynamic>> getAllChat(int receiverID)async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");

    try{
      final response = await http.get(Uri.parse("$baseUrl/chat/room?receiver_id=$receiverID"),
      headers: {"Authorization": "Bearer $token"});

      if(response.statusCode == 200){
        return json.decode(response.body);
      }else{
        throw Exception(json.decode(response.body));
      }
    }catch(e){
      throw Exception(e);
    }
  }

  Future<Map<String, dynamic>> chatSend(int receiverID, String message, XFile? gambar)async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");

    try{
      final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/chat/send"));
      request.headers.addAll({"Authorization": "Bearer $token"});
      request.fields['receiver_id'] = receiverID.toString();
      request.fields['message'] = message;
      if(gambar != null){
        request.files.add(await http.MultipartFile.fromPath("gambar", gambar.path));
      }

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      if(responseData.statusCode == 200){
        return json.decode(responseData.body);
      }else{
        return{
          "success": false,
          "message": json.decode(responseData.body)
        };
      }
    }catch(e){
      print(e);
      return{
        "success": false,
        "message": e
      };
    }
  }

  Future<dynamic> authBroadcast(String chanelName, String socketId)async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token"); // token dari login

    try{
      final response = await http.post(Uri.parse("$baseUrl/broadcasting/auth"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: json.encode({
        "socket_id": socketId,
        "channel_name": chanelName
      }));

      if(response.statusCode == 200){
        // print(json.decode(response.body));
        return json.decode(response.body);
      }else{
        throw Exception(json.decode(response.body));
      }
    }catch(e){
      throw Exception(e);
    }
  }

  Future<List<User>> getAllUser()async{
    final key = await SharedPreferences.getInstance();
    final token = await key.getString("token");

    try{
      final response = await http.get(Uri.parse("$baseUrl/chat"),
      headers: {"Authorization": "Bearer $token"});

      if(response.statusCode == 200){
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((item) => User.fromJson(item)).toList();
      }else{
        throw Exception(json.decode(response.body));
      }
    }catch(e){
      throw Exception(e);
    }
  }

  Future<User> currentUser()async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");

    try{
      final response = await http.get(Uri.parse("$baseUrl/user"),
      headers: {"Authorization": 'Bearer $token'});

      if(response.statusCode == 200){
        return User.fromJson(json.decode(response.body));
      }else{
        throw Exception(response.body);
      }
    }catch(e){
      throw Exception(e);
    }
  }

  Future<Map<String, dynamic>> updateMessage(int messageID, String message, XFile? gambar)async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");

    try{
      final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/chat/update"));
      request.headers.addAll({"Authorization": "Bearer $token"});
      request.fields['id_message'] = messageID.toString();
      request.fields['message'] = message;
      if(gambar != null){
        request.files.add(await http.MultipartFile.fromPath("gambar", gambar.path));
      }

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      if(responseData.statusCode == 200){
        return json.decode(responseData.body);
      }else{
        return{
          "success": false,
          "message": json.decode(responseData.body)
        };
      }
    }catch(e){
      return{
        "success": false,
        "message": e
      };
    }
  }

  Future<void> deleteMessage(int id)async{
    final key = await SharedPreferences.getInstance();
    final token = key.getString("token");

    try{
      await http.delete(Uri.parse("$baseUrl/chat/hapus/$id"),
      headers: {"Authorization": "Bearer $token"});
    }catch(e){
      throw Exception(e);
    }
  }
}
