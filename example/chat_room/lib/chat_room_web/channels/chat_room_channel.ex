defmodule ChatRoomWeb.ChatRoomChannel do
  use Phoenix.Channel

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
end