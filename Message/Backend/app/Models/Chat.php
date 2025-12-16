<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Chat extends Model
{
    protected $table = "chat";
    protected $fillable = ['sender_id','receiver_id'];

    function sender(){
        return $this->belongsTo(User::class,'sender_id');
    }

    function receiver(){
        return $this->belongsTo(User::class,'receiver_id');
    }
}
