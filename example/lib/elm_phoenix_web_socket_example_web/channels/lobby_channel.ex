defmodule ElmPhoenixWebSocketExampleWeb.LobbyChannel do
  use Phoenix.Channel

  alias ElmPhoenixWebSocketExample.Room
  alias ElmPhoenixWebSocketExample.User
  alias ElmPhoenixWebSocketExampleWeb.Presence


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

    push(socket, "room_list", %{rooms: Room.all()})

    {:noreply, socket}
  end

  def terminate(_reason, socket) do
    {:ok, user} = User.find(socket.assigns.user.id)

    User.delete(user)

    broadcast(socket, "room_list", %{rooms: Room.all()})
  end

  def handle_in("create_room", _, socket) do
    {:ok, user} = User.find(socket.assigns.user.id)

    User.create_room(user)

    broadcast(socket, "room_list", %{rooms: Room.all()})

    {:reply, :ok, socket}
  end
end