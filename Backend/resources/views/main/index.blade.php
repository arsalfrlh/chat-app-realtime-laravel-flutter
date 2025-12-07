<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Realtime Chat Laravel</title>

    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/css/bootstrap.min.css">

    <style>
        body {
            background: #f0f2f5;
        }
        .chat-card {
            margin-top: 40px;
            border-radius: 15px;
            overflow: hidden;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        .chat-header {
            background: linear-gradient(45deg, #007bff, #00c6ff);
            color: #fff;
            padding: 12px 20px;
            font-size: 18px;
            font-weight: bold;
        }
        .chat-body {
            height: 420px;
            overflow-y: auto;
            padding: 20px;
            background: #ffffff;
        }
        .message {
            padding: 10px 15px;
            border-radius: 20px;
            margin-bottom: 10px;
            max-width: 70%;
            word-wrap: break-word;
            display: inline-block;
            position: relative;
        }
        .message {
            white-space: pre-wrap;
            line-height: 0.7;
        }
        .message.user {
            background: #007bff;
            color: #fff;
            margin-left: auto;
            text-align: right;
        }
        .message.bot {
            background: #e9ecef;
            color: #000;
            margin-right: auto;
            text-align: left;
        }
        .edit-delete {
            font-size: 11px;
            text-align: right;
            margin-top: 3px;
        }
        .chat-footer {
            background: #f8f9fa;
            padding: 15px;
            border-top: 1px solid #dee2e6;
        }
        .text-container {
            max-width: 75%;
        }

        .d-flex .user {
            border-bottom-right-radius: 5px;
        }

        .d-flex .bot {
            border-bottom-left-radius: 5px;
        }

        .edit-delete {
            text-align: right;
        }
    </style>
</head>
<body>

<div class="container">
    <div class="card chat-card">
        <div class="chat-header">
            🔥 Realtime Chat Laravel
        </div>

        <div id="chat-box" class="chat-body">
            @foreach ($data as $c)
                <div id="chat-{{ $c->id }}" 
                    class="d-flex mb-2 {{ $c->device == 'web' ? 'justify-content-end' : 'justify-content-start' }}">
                    
                    <div class="text-container">
                        <div class="message {{ $c->device == 'web' ? 'user' : 'bot' }}">
                            {{ $c->message }}
                        </div>

                        @if($c->device == 'web')
                        <div class="edit-delete">
                            <button class="btn btn-warning btn-sm btn-edit"
                                data-id="{{ $c->id }}" data-msg="{{ $c->message }}">✏️</button>
                            <button class="btn btn-danger btn-sm btn-delete"
                                data-id="{{ $c->id }}">🗑️</button>
                        </div>
                        @endif
                    </div>
                </div>
            @endforeach
        </div>

        <div class="chat-footer">
            <form id="form-send" class="d-flex">
                <input type="text" id="message" class="form-control mr-2" placeholder="Ketik pesan..." required>
                <button type="submit" class="btn btn-primary btn-send">Kirim</button>
            </form>
        </div>
    </div>
</div>

<script src="https://js.pusher.com/7.2/pusher.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>

<script>

    const chatBox = document.getElementById("chat-box");
    function scrollBottom() { chatBox.scrollTop = chatBox.scrollHeight; }
    scrollBottom();

    var pusher = new Pusher("{{ env('PUSHER_APP_KEY') }}", {
        cluster: "{{ env('PUSHER_APP_CLUSTER') }}",
        forceTLS: true
    });

    var channel = pusher.subscribe("chat-channel");
    channel.bind("ChatUpdated", function(data) {
        if(data.action === "create") appendMessage(data.chat);
        if(data.action === "update") updateMessage(data.chat);
        if(data.action === "delete") removeMessage(data.chat.id);
        scrollBottom();
    });

    function appendMessage(chat) {
        let isWeb = chat.device === 'web';

        let div = document.createElement("div");
        div.id = "chat-" + chat.id;
        div.className = `d-flex mb-2 ${isWeb ? "justify-content-end" : "justify-content-start"}`;

        div.innerHTML = `
            <div class="text-container">
                <div class="message ${isWeb ? "user" : "bot"}">${chat.message}</div>

                ${isWeb ? `
                <div class="edit-delete">
                    <button class="btn btn-warning btn-sm btn-edit"
                            data-id="${chat.id}" data-msg="${chat.message}">✏️</button>
                    <button class="btn btn-danger btn-sm btn-delete"
                            data-id="${chat.id}">🗑️</button>
                </div>
                ` : ""}
            </div>
        `;

        chatBox.append(div);
    }

    function updateMessage(chat) {
        const msg = document.querySelector(`#chat-${chat.id} .message`);
        msg.textContent = chat.message;
    }

    function removeMessage(id) {
        const el = document.getElementById("chat-" + id);
        if(el) el.remove();
    }

    document.getElementById("form-send").addEventListener("submit", function(e){
        e.preventDefault();
        axios.post("/api/chat/tambah", {
            message: document.getElementById("message").value,
            device: "web"
        });
        document.getElementById("message").value = "";
    });

    document.addEventListener("click", function(e){
        if(e.target.classList.contains("btn-edit")){
            let id = e.target.dataset.id;
            let oldMsg = e.target.dataset.msg;
            let newMsg = prompt("Edit Pesan:", oldMsg);
            if(newMsg){
                axios.put("/api/chat/update", { id, message: newMsg });
                e.target.dataset.msg = newMsg;
            }
        }
        if(e.target.classList.contains("btn-delete")){
            let id = e.target.dataset.id;
            if(confirm("Hapus pesan ini?")){
                axios.delete(`/api/chat/hapus/${id}`);
            }
        }
    });

</script>

</body>
</html>
