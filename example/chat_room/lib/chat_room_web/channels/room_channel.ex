defmodule ChatRoomWeb.RoomChannel do
  use Phoenix.Channel

  alias ChatRoomWeb.Presence

  def join("room:public", %{"username" => username}, socket) do
    user = %{username: username, id: username <> ":" <> "#{System.system_time(:millisecond)}"}

    send(self(), :after_join)

    {:ok, user, assign(socket, user)}
  end

  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.id, %{
      online_at: inspect(System.system_time(:second)),
      username: socket.assigns.username
    })

    push(socket, "presence_state", Presence.list(socket))

    {:noreply, socket}
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