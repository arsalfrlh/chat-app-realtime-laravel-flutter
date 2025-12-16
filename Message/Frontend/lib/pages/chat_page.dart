import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:toko/models/chat.dart';
import 'package:toko/models/user.dart';
import 'package:toko/services/api_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({required this.receiver, required this.sender, super.key});
  final User sender;
  final User receiver;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ApiService apiService = ApiService();
  List<Chat> chatList = [];
  bool isLoading = false;
  final pusher = PusherChannelsFlutter.getInstance();
  final String pusherKey = "789fa48567a70c0cb876";
  final String pusherCluster = "ap1";
  XFile? gambar;
  int? messageID;
  final TextEditingController msgController = TextEditingController();
  final Color primaryOrange = const Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    fetchChat();
  }

  Future<void> fetchChat() async {
    setState(() {
      isLoading = true;
    });
    final response = await apiService.getAllChat(widget.receiver.id);
    final List<Chat> data = (response['data'] as List).map((item) => Chat.fromJson(item)).toList();
    chatList = data;
    setState(() {
      isLoading = false;
    });

    setupPusher((response['chat_id']));
  }

  Future<void> setupPusher(int chatID)async{
    await pusher.init(
      apiKey: pusherKey,
      cluster: pusherCluster,
      // authEndpoint: "http://10.0.2.2:8000/api/broadcasting/auth", //url broadcast yg sudah dibuat di route api laravel
      // onAuthorizer: (channelName, socketId, options) async { //saat mengeksekusi auth
      //   final key = await SharedPreferences.getInstance();
      //   final token = key.getString("token"); // token dari login
        
      //   final response = await http.post(
      //     Uri.parse("http://10.0.2.2:8000/api/broadcasting/auth"),
      //     headers: { //kirim authnya
      //       "Authorization": "Bearer $token",
      //       "Content-Type": "application/json",
      //     },
      //     body: jsonEncode({ //kirim bodynya
      //       "socket_id": socketId,
      //       "channel_name": channelName,
      //     }),
      //   );

      //   return jsonDecode(response.body);
      // },
      authEndpoint: "${ApiService().baseUrl}/broadcasting/auth",
      onAuthorizer: (channelName, socketId, options) async{
        final response = await apiService.authBroadcast(channelName, socketId);
        return response;
      },
      
      onEvent: (event) {
        print("Nama Event: ${event.eventName}");
        print("Data: ${event.data}");

        if(event.eventName == "ChatUpdated"){
          try{
            final data = json.decode(event.data);
            final action = data['action'];
            final message = data['message'] as Map<String, dynamic>;

            setState(() {
              if(action == 'create'){
                chatList.add(Chat.fromJson(message));
              }else if(action == 'update'){
                final int index = chatList.indexWhere((item) => item.id == message['id']);
                if(index != -1){
                  chatList[index] = Chat.fromJson(message);
                }
              }else if(action == 'delete'){
                chatList.removeWhere((item) => item.id == message['id']);
              }
            });
          }catch(e){
            print("Error decode: $e");
          }
        }
      },
      onSubscriptionSucceeded: (channelName, data) {
        print("Berhasil tersambung ke $channelName | Data: $data");
      },
      onConnectionStateChange: (currentState, previousState) {
        print("STATE: $currentState");
      },
      onError: (message, code, exception) {
        print("ERROR: $message");
      }
    );

    await pusher.subscribe(channelName: 'private-chat-room-$chatID');
    await pusher.connect();
  }

  void pilih()async{
    gambar = await ImagePicker().pickImage(source: ImageSource.gallery);
  }

  void _delete(BuildContext context, int id){
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      title: "Hapus Pesan",
      desc: "Apakah anda yakin ingin menghapus pesan?",
      btnOkOnPress: (){
        apiService.deleteMessage(id);
      },
      btnOkColor: Colors.orange,
      btnCancelOnPress: (){},
      btnCancelColor: Colors.grey
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        centerTitle: false,
        elevation: 1,
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            BackButton(color: Colors.white),
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Icon(Icons.person, size: 46, color: Colors.white)
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiver.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 220,
                  child: Text(widget.receiver.email,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                  ),
                )
              ],
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_phone),
            onPressed: () {},
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {},
            color: Colors.white,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchChat,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                itemCount: chatList.length,
                // show messages from older to newer. If your API returns newest first,
                // you might want to reverse the list or change index access.
                itemBuilder: (context, index) {
                  final msg = chatList[index];
                  final isMe = msg.user.id == widget.sender.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment:
                          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe) ...[
                          // small avatar for left side
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                                    width: 36,
                                    height: 36,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.person, size: 20),
                                  )
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: _ChatBubble(
                            messages: msg,
                            isMe: isMe,
                            orange: primaryOrange,
                            onUpdate: (){
                              setState(() {
                                messageID = msg.id;
                                msgController.text = msg.message;
                              });
                            },
                            onDelete: () => _delete(context, msg.id),
                          ),
                        ),
                        if (isMe) const SizedBox(width: 44) // keep spacing for right side
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          ChatInputField(
            pilih: pilih,
            ctrl: msgController,
            onSend: (String text) async{
              if(text.isNotEmpty){
                final response = messageID != null && msgController.text.isNotEmpty ? await apiService.updateMessage(messageID!, text, gambar) : await apiService.chatSend(widget.receiver.id, text, gambar);
                setState(() {
                  messageID = null;
                  msgController.clear();
                });
                if(response['success'] == false){
                  AwesomeDialog(
                    context: context,
                    dialogType: DialogType.error,
                    animType: AnimType.bottomSlide,
                    title: "Error",
                    desc: response['message'].toString(),
                    btnOkColor: Colors.red,
                    btnOkOnPress: (){}
                  ).show();
                }
              }
            },
            orange: primaryOrange,
            isUpdate: messageID != null,
            onCacel: (){
              setState(() {
                messageID = null;
                msgController.clear();
              });
            },
          ),
        ],
      ),
    );
  }
}

class ChatInputField extends StatefulWidget {
  final void Function(String text)? onSend;
  final Color? orange;
  ChatInputField({this.onSend, this.orange, super.key, required this.pilih, required this.onCacel, required this.ctrl, required this.isUpdate});
  final VoidCallback pilih, onCacel;
  final TextEditingController ctrl;
  bool isUpdate;

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  bool _showAttachment = false;

  @override
  Widget build(BuildContext context) {
    final orange = widget.orange ?? const Color(0xFFFF9800);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -3),
            blurRadius: 12,
            color: Colors.black.withOpacity(0.03),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: widget.pilih,
              icon: Icon(Icons.add_circle_outline),
              color: orange,
            ),
            Expanded(
              child: TextField(
                controller: widget.ctrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if(widget.isUpdate)
                      IconButton(
                        icon: Icon(Icons.cancel_outlined,
                            color: _showAttachment ? orange : Colors.grey),
                        onPressed: widget.onCacel,
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt_outlined),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                final text = widget.ctrl.text.trim();
                if (text.isNotEmpty) {
                  widget.onSend?.call(text);
                  widget.ctrl.clear();
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: orange,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: orange.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.send, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final Chat messages;
  final bool isMe;
  final Color orange;
  final VoidCallback onDelete, onUpdate;
  const _ChatBubble({
    required this.messages,
    required this.isMe,
    required this.orange,
    required this.onUpdate,
    required this.onDelete
  });

  @override
  Widget build(BuildContext context) {
    // max width so bubble doesn't stretch full screen
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.72;

    // background for bubble: orange filled for me, light orange translucent for others
    final backgroundColor = isMe ? orange : orange.withOpacity(0.08);
    final textColor = isMe ? Colors.white : Colors.black87;

    // We'll show gambar first (if present), then message text (if non-empty).
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (messages.gambar != null && messages.gambar!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                  bottom: messages.message.isNotEmpty ? 8.0 : 0.0),
              child: Container(
                // image container with rounded corners + shadow (chosen option)
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl:
                        "http://10.0.2.2:8000/images/${messages.gambar}",
                    placeholder: (context, url) => AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    errorWidget: (context, url, error) => AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    // set height but let BoxFit cover manage crop
                    height: 200,
                  ),
                ),
              ),
            ),
          if (messages.message.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMe ? 18 : 6),
                  topRight: Radius.circular(isMe ? 6 : 18),
                  bottomLeft: const Radius.circular(18),
                  bottomRight: const Radius.circular(18),
                ),
              ),
              child: Text(
                messages.message,
                style: TextStyle(color: textColor, fontSize: 15),
              ),
            ),
          const SizedBox(height: 6),
          // small timestamp (optional)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(messages.createAt),
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400),
              ),
              const SizedBox(width: 6),
              if (isMe)
              messages.status == 'read'
                ? Icon(
                  Icons.done_all,
                  size: 14,
                  color: Colors.green,
                )
                : Icon(
                  Icons.done_all,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                if(isMe)
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, size: 15,),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text("Edit"),
                      onTap: onUpdate,
                    ),
                    PopupMenuItem(
                      child: const Text("Hapus"),
                      onTap: onDelete,
                    ),
                  ],
                ),
            ],
          )
        ],
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    try {
      // show only hour:minute, safe for nulls
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "";
    }
  }
}