defmodule ChatRoomWeb.MultiRoomChannel do
  use Phoenix.Channel

  alias ChatRoom.User
  alias ChatRoomWeb.Presence

  def join("example:lobby", %{"username" => username}, socket) do
    user =
      %{id: inspect(rem System.system_time(:millisecond), 1_000_000),
        username: username,
        rooms: []
      }

    :ets.insert(:users_table, {user.id, user})

    send(self(), :after_join)

    {:ok, user, assign(socket, %{user: user})}
  end

  def handle_info(:after_join, socket) do
    {:ok, presence} = Presence.track(socket, socket.assigns.user.id, %{
      online_at: System.system_time(:millisecond),
      device: ""
    })

    push(socket, "presence_state", Presence.list(socket))

    {:noreply, socket}
  end

  def terminate(_reason, socket) do
    :ets.delete(:users_table, socket.assigns.user.id)
  end

  def handle_in("create_room", _, socket) do
    room_id = inspect System.system_time(:millisecond)

    {:ok, user} = User.find(socket.assigns.user.id)

    room =
      %{id: room_id,
        owner: %{id: user.id, username: user.username},
        messages: []
      }

    user =
      Map.update(user, :rooms, [room.id], &([room.id | &1]))

    :ets.insert(:rooms_table, {room.id, room})
    :ets.insert(:users_table, {user.id, user})

    broadcast(socket, "new_room", room)

    {:reply, :ok, socket}
  end

  def handle_in("new_msg", %{"msg" => msg, "id" => id}, socket) do
    broadcast(socket, "new_msg", %{id: id, text: msg})

    {:reply, :ok, socket}
  end

  def handle_in("is_typing", %{"id" => id}, socket) do
    broadcast(socket, "is_typing", %{id: id})

    {:noreply, socket}
  end

  def handle_in("stopped_typing", %{"id" => id}, socket) do
    broadcast(socket, "stopped_typing", %{id: id})

    {:noreply, socket}
  end
end