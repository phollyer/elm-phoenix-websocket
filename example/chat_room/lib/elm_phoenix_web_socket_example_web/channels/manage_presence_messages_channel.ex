defmodule ElmPhoenixWebSocketExampleWeb.ManagePresenceMessagesChannel do
  use Phoenix.Channel

  alias ElmPhoenixWebSocketExampleWeb.Presence

  def join("example:manage_presence_messages", _, socket) do
    {:ok, %{example_id: inspect(System.system_time(:millisecond))}, socket}
  end

  def join("example:manage_presence_messages_" <> example_id, _, socket) do
    send(self(), :after_join)

    user_id = inspect(System.system_time(:millisecond))

    {:ok, %{user_id: user_id}, assign(socket, :user_id, user_id)}
  end

  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{})

    push(socket, "presence_state", Presence.list(socket))

    {:noreply, socket}
  end
end