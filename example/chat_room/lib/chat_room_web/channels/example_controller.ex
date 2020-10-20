defmodule ChatRoomWeb.ExampleControllerChannel do
  use Phoenix.Channel

  alias ChatRoomWeb.Presence

  def join("example_controller:control", _, socket) do
    {:ok, %{example_id: inspect(System.system_time(:millisecond))}, socket}
  end

  def join("example_controller:" <> example_id, _, socket) do
    send(self(), :after_join)

    user_id = inspect(System.system_time(:millisecond))

    {:ok, %{user_id: user_id}, assign(socket, :user_id, user_id)}
  end

  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
      example_state: "Not Joined"
    })

    push(socket, "presence_state", Presence.list(socket))

    {:noreply, socket}
  end

  def handle_in("join_example", params, socket) do
    broadcast(socket, "join_example", params)

    {:reply, :ok, socket}
  end

  def handle_in("joining_example", nil, socket) do
    Presence.update(socket, socket.assigns.user_id, %{example_state: "Joining"})

    {:reply, :ok, socket}
  end

  def handle_in("joined_example", _, socket) do
    Presence.update(socket, socket.assigns.user_id, %{example_state: "Joined"})

    {:reply, :ok, socket}
  end

  def handle_in("leave_example", params, socket) do
    broadcast(socket, "leave_example", params)

    {:reply, :ok, socket}
  end

  def handle_in("leaving_example", _, socket) do
    Presence.update(socket, socket.assigns.user_id, %{example_state: "Leaving"})

    {:reply, :ok, socket}
  end

  def handle_in("left_example", _, socket) do
    Presence.update(socket, socket.assigns.user_id, %{example_state: "Left"})

    {:reply, :ok, socket}
  end
end