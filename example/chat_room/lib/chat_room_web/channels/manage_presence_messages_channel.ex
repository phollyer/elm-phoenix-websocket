defmodule ChatRoomWeb.ManagePresenceMessagesChannel do
  use Phoenix.Channel

  alias ChatRoomWeb.Presence

  def join("example:manage_presence_messages", _, socket) do
    send(self(), :after_join)

    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, inspect(System.system_time(:millisecond)), %{
      online_at: System.system_time(:millisecond),
    })

    push(socket, "presence_state", Presence.list(socket))

    {:noreply, socket}
  end
end