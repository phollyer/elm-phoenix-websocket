defmodule ChatRoomWeb.PushEventsChannel do
  use Phoenix.Channel

  def join("example:push_events", _, socket) do

    {:ok, socket}
  end

  def handle_in("example_push", _, socket) do
    {:reply, :ok, socket}
  end
end