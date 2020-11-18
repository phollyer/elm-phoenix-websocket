defmodule ElmPhoenixWebSocketExampleWeb.ElmPhoenixWebSocketExampleChannel do
  use Phoenix.Channel

  alias ElmPhoenixWebSocketExample.Message
  alias ElmPhoenixWebSocketExample.Room
  alias ElmPhoenixWebSocketExample.User
  alias ElmPhoenixWebSocketExampleWeb.Presence

  def join("example:room:" <> room_id, %{"id" => user_id}, socket) do
    {:ok, user} = User.find(user_id)

    {:ok, room} = Room.find(room_id)

    Room.add_member(room.id, user)

    send(self(), :after_join)

    {:ok, room, assign(socket, %{user_id: user.id, room_id: room.id})}
  end

  def handle_info(:after_join, socket) do
    {:ok, presence} = Presence.track(socket, socket.assigns.user_id, %{
      online_at: System.system_time(:millisecond)
    })

    push(socket, "presence_state", Presence.list(socket))

    push(socket, "message_list", %{messages: Room.messages(socket.assigns.room_id)})

    broadcast_room_list()

    {:noreply, socket}
  end

  def terminate(_reason, socket) do
    case Room.find(socket.assigns.room_id) do
      {:ok, room} ->
        if socket.assigns.user_id == room.owner.id do
          Room.delete(room)

          broadcast(socket, "room_deleted", room)
        else
          Room.delete_member(room, socket.assigns.user_id)
        end

      :not_found ->
        nil
    end

    broadcast_room_list()
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
    {:ok, user} = User.find(socket.assigns.user_id)

    Room.add_message(socket.assigns.room_id, Message.create(message, user))

    broadcast(socket, "message_list", %{messages: Room.messages(socket.assigns.room_id)})

    {:reply, :ok, socket}
  end


  defp broadcast_room_list do
    ElmPhoenixWebSocketExampleWeb.Endpoint.broadcast("example:lobby", "room_list", %{rooms: Room.all()})
  end
end