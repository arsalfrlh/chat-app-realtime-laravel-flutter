<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ChatUpdate implements ShouldBroadcast //tamabahkan implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    //membuat variabel public dlm class
    public $action; //utk menyimpan Action (create, update, hapus)
    public $chat; //utk menyimpan model Chat
    public function __construct($action, $chat) //di class ini punya konstruktor dgn 2 parameter| jadi saat memanggil model ini butuh 2 parameter yg harus di isi
    {
        $this->action = $action; //set variabel dlm class ini isinya dari konstruktor
        $this->chat = $chat;
    }

    public function broadcastOn()
    {
        return new Channel('chat-channel'); //nama Channel Event
    }

    public function broadcastAs(){
        return "ChatUpdated"; //nama Event
    }

    public function broadcastWith(){
        return [ //saat create, update, delete di response eventnya akan ada action, dan chat
            'action' => $this->action,
            'chat' => $this->chat
        ];
    }

    //jika ingin nama chanelnya banyak bisa gunakan seperti ini
    // public function broadcastOn(): array
    // {
    //     return [
    //         new PrivateChannel('chat-channel'), //nama Chanel Event
    //         new Channel('barang-channel'), //nama Chanel Event
    //     ];
    // }
}
