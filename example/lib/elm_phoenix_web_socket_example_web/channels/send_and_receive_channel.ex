defmodule ElmPhoenixWebSocketExampleWeb.SendAndReceiveChannel do
  use Phoenix.Channel

  def join("example:send_and_receive", _, socket) do

    {:ok, socket}
  end

  def handle_in("example_push", _, socket) do
    {:reply, :ok, socket}
  end

  def handle_in("receive_events", _, socket) do
    push( socket, "receive_event_1", %{"event" => "1"} )
    push( socket, "receive_event_2", %{"event" => "2"} )

    {:reply, :ok, socket}
  end

  def handle_in("push_with_timeout", _, socket) do
    {:noreply, socket}
  end
end