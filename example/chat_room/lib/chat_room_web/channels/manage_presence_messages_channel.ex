defmodule ChatRoomWeb.ManagePresenceMessagesChannel do
  use Phoenix.Channel

  alias ChatRoomWeb.Presence

  def join("example:manage_presence_messages", %{"user_id" => user_id}, socket) do
    send(self(), :after_join)

    {:ok, assign(socket, :user_id, user_id)}
  end

  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
      online_at: System.system_time(:millisecond),
    })

    push(socket, "presence_state", Presence.list(socket))

    {:noreply, socket}
  end
end