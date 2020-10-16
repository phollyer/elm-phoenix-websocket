defmodule ChatRoomWeb.ManageChannelMessagesChannel do
  use Phoenix.Channel

  def join("example:manage_channel_messages", _, socket) do

    {:ok, socket}
  end

  def handle_in("empty_message", _, socket) do
    push(socket, "example_return_push", %{foo: "Bar"})

    {:reply, :ok, socket}
  end
end