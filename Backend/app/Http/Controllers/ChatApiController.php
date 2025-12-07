<?php

namespace App\Http\Controllers;

use App\Events\ChatUpdate;
use App\Models\Chat;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

//atur configurasi pusher di .env
//install pusher "composer require pusher/pusher-php-server"

class ChatApiController extends Controller
{
    public function webIndex(){
        $data = Chat::orderBy('id','desc')->get();
        return view('main.index', ['data' => $data]);
    }

    public function index(){
        $data = Chat::orderBy('id','desc')->get();
        return response()->json(['message' => "Menampilkan hasil percakapan", 'success' => true, 'data' => $data]);
    }

    public function create(Request $request){
        $validator = Validator::make($request->all(),[
            'message' => 'required'
        ]);

        if($validator->fails()){
            return response()->json(['message' => $validator->errors()->all(), 'success' => false]);
        }

        //$data bentuknya masih Model Eloquent langsung
        $data = Chat::create([
            'device' => $request->device ?? 'web',
            'message' => $request->message
        ]);
        
        event(new ChatUpdate('create', $data));
        return response()->json(['message' => "Pesan berhasil dikirim", 'success' => true, 'data' => $data]);
    }

    public function update(Request $request){
        $validator = Validator::make($request->all(),[
            'id' => 'required|numeric',
            'message' => 'required'
        ]);

        if($validator->fails()){
            return response()->json(['message' => $validator->errors()->all(), 'success' => false]);
        }

        $data = Chat::find($request->id);
        $data->update([
            'message' => $request->message
        ]);
        event(new ChatUpdate('update',$data));

        // contoh hasil response
        // {
        //     "message": "Pesan berhasil di update",
        //     "success": false,
        //     "data": {
        //         "id": 3,
        //         "device": "web",
        //         "message": "Pe1",
        //         "created_at": "2025-11-30T06:24:04.000000Z",
        //         "updated_at": "2025-11-30T09:20:38.000000Z"
        //     }
        // }
        return response()->json(['message' => "Pesan berhasil di update", 'success' => true, 'data' => $data]);
    }

    public function destroy($id){
        $message = Chat::where('id', $id)->first();
        //$data bentuknya masih Model Eloquent| tapi di bawah di hapus jadi bukan Model Eloquent jadi harus pakai toArray() 
        $data = $message->toArray();
        $message->delete();

        event(new ChatUpdate('delete', $data));
        return response()->json(['message' => "Pesan telah dihapus", 'success' => true, 'data' => $data]);
    }
}
