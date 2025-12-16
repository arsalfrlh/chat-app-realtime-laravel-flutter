<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MessageUpdate implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    protected $message;
    protected $chatID;
    protected $action;
    public function __construct($message, $chatID, $action)
    {
        $this->message = $message;
        $this->chatID = $chatID;
        $this->action = $action;
    }

    public function broadcastOn()
    {
        return new PrivateChannel('chat-room-'.$this->chatID); //buat private
    }

    public function broadcastAs(){
        return "ChatUpdated";
    }

    public function broadcastWith(){
        return [
            'action' => $this->action,
            'message' => $this->message
        ];
    }
}
