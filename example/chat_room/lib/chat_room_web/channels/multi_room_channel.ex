defmodule ChatRoomWeb.MultiRoomChannel do
  use Phoenix.Channel

  alias ChatRoom.Room
  alias ChatRoom.User
  alias ChatRoomWeb.Presence

  def join("example:lobby", %{"username" => username}, socket) do
    {:ok, user} =
      User.create(username)
      |> User.update()

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
    User.delete(socket.assigns.user)
  end

  def handle_in("create_room", _, socket) do
    {:ok, user} = User.find(socket.assigns.user.id)

    {:ok, room} =
      Room.create(user)
      |> Room.update()

    User.new_room(user, room.id)
    |> User.update()

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