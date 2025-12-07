import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:toko/models/chat.dart';
import 'package:toko/services/api_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ApiService apiService = ApiService();
  final messageController = TextEditingController();
  List<Chat> chatList = [];
  bool isLoading = false;
  final pusher = PusherChannelsFlutter.getInstance();
  final String pusherKey = "789fa48567a70c0cb876";
  final String pusherCluster = "ap1";
  int? chatId;

  @override
  void initState() {
    super.initState();
    fetchChat();
    setupPusher();
  }

  Future<void> fetchChat()async{
    setState(() {
      isLoading = true;
    });
    chatList = await apiService.getAllChat();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> setupPusher()async{
    await pusher.init(
      apiKey: pusherKey,
      cluster: pusherCluster,
      onEvent: (event) {
        print("Nama Event: ${event.eventName}");
        print("Data: ${event.data}");

        if(event.eventName == "ChatUpdated"){ //nama event dari Event laravel function broadcastAs()
          try{
            final data = json.decode(event.data) as Map<String, dynamic>;
            final action = data['action']; //action dari controller laravel(create)| arraykey action dari event laravel function broadcastWith
            final chat = data['chat'] as Map<String, dynamic>; //arraykey chat dari event laravel function broadcastWith

            setState(() {
              if(action == 'create'){
                //insert model Chat baru ke list model Chat| index 0 dan model Chat 
                chatList.insert(0, Chat.fromJson(chat));
              }else if(action == 'update'){
                //mencari index di List model Chat berdasarkan id dari response event
                final int index = chatList.indexWhere((chats) => chats.id == chat['id']);
                if(index != -1){
                  chatList[index] = Chat.fromJson(chat);
                }
                // bisa seperti ini juga
                // for(int i = 0; i < chatList.length; i++){
                //   if(chatList[i].id == chat['id']){
                //      chatList[i] = Chat.fromJson(chat);
                //   }
                // }
              }else if(action == 'delete'){
                //mencari dan menghapus dari List model Chat berdasarkan id dari response event
                chatList.removeWhere((chats) => chats.id == chat['id']);
              }
            });
          }catch(e){
            print("Error decode: $e");
          }
        }
      },
      onSubscriptionSucceeded: (channelName, data) {
        print("Berhasil tersambung ke chanel: $channelName| Data: $data");
      },
      onConnectionStateChange: (currentState, previousState) {
        print("STATE: $currentState");
      },
      onError: (message, code, exception) {
        print("ERROR: $message");
      }
    );

    await pusher.subscribe(channelName: 'chat-channel');
    await pusher.connect();
  }

  void _send(BuildContext context)async{
    if(messageController.text.isNotEmpty){
      showDialog(
        context: context, 
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(),));
      //jika chatId tidak null endpoint ke update jika null end point ke add
      final response = chatId != null ? await apiService.updateChat(chatId!, messageController.text) : await apiService.sendChat(messageController.text);
      setState(() {
        messageController.clear();
        chatId = null;
      });

      Navigator.of(context, rootNavigator: true).pop();

      if(response['success'] == false){
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.bottomSlide,
          dismissOnTouchOutside: false,
          title: "Error",
          desc: response['message'].toString(),
          btnOkOnPress: (){},
          btnOkColor: Colors.red
        ).show();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFF00BF6D),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            BackButton(),
            ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(50),
              child: CachedNetworkImage(imageUrl: "https://avatars.githubusercontent.com/u/144583426?v=4", fit: BoxFit.cover, width: 40, height: 40, errorWidget: (context, url, error) => Icon(Icons.broken_image, size: 40,),),
            ),
            SizedBox(width: 16.0 * 0.75),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "App Chat Realtime",
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  "Online",
                  style: TextStyle(fontSize: 12),
                )
              ],
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_phone),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {},
          ),
          const SizedBox(width: 16.0 / 2),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                itemCount: chatList.length,
                itemBuilder: (context, index) => Message(
                  chat: chatList[index],
                  onEdit: (id, msg) { //set isi parameter functionnya dari class Message
                    setState(() {
                      messageController.text = msg;
                      chatId = id;
                    });
                  },
                ),
              ),
            ),
          ),
          ChatInputField(
            onSend: () => _send(context),
            message: messageController,
            chatId: chatId,
          ),
        ],
      ),
    );
  }
}

class ChatInputField extends StatefulWidget {
  ChatInputField({required this.message, required this.onSend, required this.chatId});
  final TextEditingController message;
  final VoidCallback onSend;
  int? chatId;

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  bool _showAttachment = false;

  void _updateAttachmentState() {
    setState(() {
      _showAttachment = !_showAttachment;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 16.0 / 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -4),
            blurRadius: 32,
            color: const Color(0xFF087949).withOpacity(0.08),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                if(widget.chatId != null) //cek apakah chatId null jika tidak akan tampil ink well
                InkWell(
                  child: Icon(Icons.remove_circle_outline_outlined, color: Colors.red),
                  onTap: (){
                    setState(() {
                      widget.chatId = null;
                      widget.message.clear();
                    });
                  },
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Row(
                    children: [
                      const SizedBox(width: 16.0 / 4),
                      Expanded(
                        child: TextField(
                          controller: widget.message,
                          decoration: InputDecoration(
                            hintText: widget.chatId == null ? "Type message" : "Update message",
                            suffixIcon: SizedBox(
                              width: 65,
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: _updateAttachmentState,
                                    child: Icon(
                                      Icons.attach_file,
                                      color: _showAttachment
                                          ? const Color(0xFF00BF6D)
                                          : Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .color!
                                              .withOpacity(0.64),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0 / 2),
                                    child: InkWell(
                                      onTap: widget.onSend,
                                        child: Icon(
                                        Icons.send,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .color!
                                            .withOpacity(0.64),
                                      ),
                                    )
                                  ),
                                ],
                              ),
                            ),
                            filled: true,
                            fillColor:
                                const Color(0xFF00BF6D).withOpacity(0.08),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0 * 1.5, vertical: 16.0),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(50)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_showAttachment) const MessageAttachment(),
          ],
        ),
      ),
    );
  }
}

class MessageAttachment extends StatelessWidget {
  const MessageAttachment({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      // color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          MessageAttachmentCard(
            iconData: Icons.insert_drive_file,
            title: "Document",
            press: () {},
          ),
          MessageAttachmentCard(
            iconData: Icons.image,
            title: "Gallary",
            press: () {},
          ),
          MessageAttachmentCard(
            iconData: Icons.headset,
            title: "Audio",
            press: () {},
          ),
          MessageAttachmentCard(
            iconData: Icons.videocam,
            title: "Video",
            press: () {},
          ),
        ],
      ),
    );
  }
}

class MessageAttachmentCard extends StatelessWidget {
  final VoidCallback press;
  final IconData iconData;
  final String title;

  const MessageAttachmentCard(
      {super.key,
      required this.press,
      required this.iconData,
      required this.title});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      child: Padding(
        padding: const EdgeInsets.all(16.0 / 2),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0 * 0.75),
              decoration: const BoxDecoration(
                color: Color(0xFF00BF6D),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                size: 20,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
            const SizedBox(height: 16.0 / 2),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .color!
                        .withOpacity(0.8),
                  ),
            )
          ],
        ),
      ),
    );
  }
}

class Message extends StatefulWidget {
  final Chat chat;
  final Function(int id, String message) onEdit; //function yang punya 2 parameter

  Message({
    super.key,
    required this.chat,
    required this.onEdit,
  });

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {

  @override
  Widget build(BuildContext context) {
    final isSender = widget.chat.device == "mobile";
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment:
            isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:
                  const Color(0xFF00BF6D).withOpacity(isSender ? 1 : 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.chat.message,
                    style: TextStyle(
                      color: isSender ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Jam di dalam bubble
                Text(
                  DateFormat('HH:mm').format(widget.chat.createAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isSender ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(width: 6),

                // 🔥 Icon titik 3 di sini
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  color: Colors.white,
                  onSelected: (value) async{
                    if (value == 'copy') {
                      Clipboard.setData(
                        ClipboardData(text: widget.chat.message),
                      );
                    } else if (value == 'delete') {
                      showDialog(
                      context: context, 
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator(),));
                      await ApiService().deleteChat(widget.chat.id);
                      Navigator.of(context, rootNavigator: true).pop();
                    } else if (value == 'edit') {
                      widget.onEdit(widget.chat.id, widget.chat.message); //set isi parameter functionnya
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'copy', child: Text("Copy")),
                    const PopupMenuItem(value: 'edit', child: Text("Edit")),
                    const PopupMenuItem(value: 'delete', child: Text("Delete")),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
