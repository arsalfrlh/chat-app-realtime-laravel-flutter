<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('message', function (Blueprint $table) {
            $table->integer('id')->primary()->autoIncrement();
            $table->integer('chat_id');
            $table->integer('id_user');
            $table->text('message');
            $table->string('gambar')->nullable();
            $table->enum('status',['read','unread'])->default('unread');
            $table->timestamps();

            $table->foreign('chat_id')->on('chat')->references('id')->onDelete('cascade');
            $table->foreign('id_user')->on('users')->references('id')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('message');
    }
};
