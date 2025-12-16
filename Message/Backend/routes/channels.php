<?php

use App\Models\Chat;
use App\Models\Message;
use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('chat-room-{chatID}', function ($user, $chatID) { //ini dari Event MessageUpdate (function broadcastOn())
    // return true; // sementara allow semua (bisa diperketat nanti)| logic siapa yang bisa akses
    // parameter $user itu adalah current user yg login dgn Auth Bearer
    //yang bisa akses hanya current user dan (sender dan receiver)
    Message::where('chat_id', $chatID)->where('status','!=','read')->where('id_user','!=',$user->id)->update([
        'status' => 'read'
    ]);
    return Chat::where('id', $chatID)
        ->where(function ($query) use ($user) { //masuk ke orm where
            $query->where('sender_id', $user->id) //dan where dibagi menjadi 2 where dan orWhere
                  ->orWhere('receiver_id', $user->id);
        })
        ->exists(); //hasilnya true jika exist di database
});

//contoh raw sql
// SELECT *
// FROM chat
// WHERE id = $chatID
// AND (
//     sender_id = $userId
//     OR receiver_id = $userId
// )
// LIMIT 1;

// gunakan seperti ini jika penasaran
// dd(
//     Chat::where('id', $chatID)
//         ->where(function ($query) use ($user) {
//             $query->where('sender_id', $user->id)
//                   ->orWhere('receiver_id', $user->id);
//         })
//         ->toSql()
// );