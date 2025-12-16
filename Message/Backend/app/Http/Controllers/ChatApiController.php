<?php

namespace App\Http\Controllers;

use App\Events\MessageUpdate;
use App\Models\Chat;
use App\Models\Message;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ChatApiController extends Controller
{
    public function index(Request $request){
        $data = User::where('id', '!=', $request->user()->id)->get();
        return response()->json(['message' => "Menampilkan daftar user", 'success' => true, 'data' => $data]);
    }

    public function chatRoom(Request $request){
        $validator = Validator::make($request->all(),[
            'receiver_id' => 'required'
        ]);
        if($validator->fails()){
            return response()->json(['message' => $validator->errors()->all(), 'success' => false]);
        }

        $receiver = $request->get('receiver_id');
        $user = $request->user();
        $chat = Chat::where('sender_id', $user->id)->where('receiver_id', $receiver)->orWhere('sender_id', $receiver)->where('receiver_id', $user->id)->first();
        if(!$chat){
            $chat = Chat::create([
                'sender_id' => $user->id,
                'receiver_id' => $receiver
            ]);
        }

        $data = Message::with('user')->where('chat_id', $chat->id)->get();
        Message::where('chat_id', $chat->id)->where('status','!=','read')->where('id_user','!=',$user->id)->update([
            'status' => 'read'
        ]);
        return response()->json(['message' => "Menampilkan percakapan", 'success' => true, 'data' => $data, 'chat_id' => $chat->id]);
        
        // $message = Message::with('user')->where('chat_id', $chat->id)->where('status','!=','read')->where('id_user','!=',$user->id)->get();
        // if(count($message) > 0){
        //     foreach($message as $dataMessage){
        //             $dataMessage->update([
        //             'status' => 'read'
        //         ]);
        //     }
        // }
        // return response()->json(['message' => "Menampilkan percakapan", 'success' => true, 'data' => $data, 'chat_id' => $chat->id, 'message' => $message]);
    }

    public function chatSend(Request $request){
        $validator = Validator::make($request->all(),[
            'receiver_id' => 'required|numeric',
            'message' => 'required',
            'gambar' => 'nullable|image|mimes:jpg,jpeg,png'
        ]);

        if($validator->fails()){
            return response()->json(['message' => $validator->errors()->all(), 'success' => false]);
        }

        $receiver = $request->receiver_id;
        $user = $request->user();
        $chat = Chat::where('sender_id',$user->id)->where('receiver_id', $receiver)->orWhere('sender_id', $receiver)->where('receiver_id', $user->id)->first();
        if(!$chat){
            $chat = Chat::create([
                'sender_id' => $user->id,
                'receiver_id' => $receiver
            ]);
        }

        if($request->hasFile('gambar')){
            $gambar = $request->file('gambar');
            $nmgambar = time() . '_' . $gambar->getClientOriginalName();
            $gambar->move(public_path('images'), $nmgambar);
        }else{
            $nmgambar = null;
        }

        $message = Message::create([
            'chat_id' => $chat->id,
            'id_user' => $user->id,
            'message' => $request->message,
            'gambar' => $nmgambar,
        ]);

        $data = Message::with('user')->find($message->id);

        Message::where('chat_id', $chat->id)->where('status','!=','read')->where('id_user','!=',$user->id)->update([
            'status' => 'read'
        ]);
        event(new MessageUpdate($data, $chat->id, "create"));
        return response()->json(['message' => "Pesan berhasil dikirim", 'success' => true, 'data' => $data]);
    }

    public function chatUpdate(Request $request){
        $validator = Validator::make($request->all(),[
            'id_message' => 'required|numeric',
            'message' => 'required',
            'gambar' => 'nullable|image|mimes:jpeg,jpg,png'
        ]);

        if($validator->fails()){
            return response()->json(['message' => $validator->errors()->all(), 'success' => false]);
        }

        $user = $request->user();
        $data = Message::with('user')->find($request->id_message);
        if($request->hasFile('gambar')){
            if(!is_null($data->gambar) && file_exists(public_path('images/'.$data->gambar))){
                unlink(public_path('images/'.$data->gambar));
            }

            $gambar = $request->file('gambar');
            $nmgambar = time() . '_' . $gambar->getClientOriginalName();
            $gambar->move(public_path('images'), $nmgambar);
        }else{
            $nmgambar = $data->gambar;
        }

        $data->update([
            'message' => $request->message,
            'gambar' => $nmgambar,
        ]);
        Message::where('chat_id', $data->chat_id)->where('status','!=','read')->where('id_user','!=',$user->id)->update([
            'status' => 'read'
        ]);
        event(new MessageUpdate($data, $data->chat_id, 'update'));
        return response()->json(['message' => "Pesan telah diupdate", 'success' => true, 'data' => $data]);
    }

    public function destroy($id){
        $message = Message::with('user')->find($id);
        $data = $message->toArray();
        if(!is_null($message->gambar) && file_exists(public_path('images/'.$message->gambar))){
            unlink(public_path('images/'.$message->gambar));
        }
        $message->delete();

        event(new MessageUpdate($data, $message->chat_id, 'delete'));
        return response()->json(['message' => "Pesan telah dihapus", 'success' => true, 'data' => $data]);
    }
}
