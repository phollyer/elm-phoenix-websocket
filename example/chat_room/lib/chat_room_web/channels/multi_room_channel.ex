defmodule ChatRoomWeb.MultiRoomChannel do
  use Phoenix.Channel

  alias ChatRoomWeb.Presence

  def join("example:lobby", %{"username" => username}, socket) do
    user = %{username: username, id: inspect (rem System.system_time(:millisecond), 1_000_000)}

    :ets.delete_all_objects(:users_table)
    :ets.insert(:users_table, {user.id, %{username: username, id: user.id}})

    IO.inspect(:ets.lookup(:users_table,user.id))

    send(self(), :after_join)

    {:ok, user, assign(socket, %{user: user})}
  end

  def handle_info(:after_join, socket) do
    {:ok, presence} = Presence.track(socket, socket.assigns.user.id, %{
      rooms: []
    })

    push(socket, "presence_state", Presence.list(socket))

    {:noreply, socket}
  end

  def handle_in("create_room", %{"user_id" => user_id}, socket) do
    broadcast(socket, "new_room", %{id: user_id})

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