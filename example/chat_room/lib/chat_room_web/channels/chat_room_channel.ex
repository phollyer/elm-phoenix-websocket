defmodule ChatRoomWeb.ChatRoomChannel do
  use Phoenix.Channel

  alias ChatRoom.Message
  alias ChatRoom.Room
  alias ChatRoom.User
  alias ChatRoomWeb.Presence

  def join("example:room:" <> room_id, %{"id" => user_id}, socket) do
    {:ok, user} = User.find(user_id)

    {:ok, room} = Room.find(room_id)

    send(self(), :after_join)

    {:ok, room, assign(socket, %{user: user, room: room})}
  end

  def handle_info(:after_join, socket) do
    {:ok, presence} = Presence.track(socket, socket.assigns.user.id, %{
      online_at: System.system_time(:millisecond)
    })

    push(socket, "presence_state", Presence.list(socket))

    push(socket, "message_list", %{messages: Room.messages(socket.assigns.room.id)})

    {:noreply, socket}
  end

  def terminate(_reason, socket) do
  end

  def handle_in("member_started_typing", user, socket) do
    broadcast(socket, "member_started_typing", user)

    {:reply, :ok, socket}
  end

  def handle_in("member_stopped_typing", user, socket) do
    broadcast(socket, "member_stopped_typing", user)

    {:reply, :ok, socket}
  end

  def handle_in("new_message", %{"message" => message}, socket) do
    message = Message.create(message, socket.assigns.user)

    Room.add_message(socket.assigns.room.id, message)

    broadcast(socket, "message_list", %{messages: Room.messages(socket.assigns.room.id)})

    {:reply, :ok, socket}
  end
end