<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    protected $table = "message";
    protected $fillable = ['chat_id','id_user','message','gambar','status'];

    function user(){
        return $this->belongsTo(User::class,'id_user');
    }
}
