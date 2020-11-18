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

    Enum.map(user.rooms, &(Room.find(&1)))
      |> Enum.each(fn result ->
        case result do
          {:ok, room} ->
            broadcast(socket, "room_deleted", room)
          :not_found ->
            nil
        end
      end)

    User.delete(user)

    broadcast_room_list(socket)
  end

  def handle_in("create_room", _, socket) do
    {:ok, user} = User.find(socket.assigns.user.id)

    User.create_room(user)

    broadcast_room_list(socket)

    {:reply, :ok, socket}
  end

  def handle_in("delete_room", %{"room_id" => room_id}, socket) do
    {:ok, room} = Room.find(room_id)

    Room.delete(room)

    broadcast_room_list(socket)

    {:reply, :ok, socket}
  end


  defp broadcast_room_list(socket) do
    broadcast(socket, "room_list", %{rooms: Room.all()})
  end
end