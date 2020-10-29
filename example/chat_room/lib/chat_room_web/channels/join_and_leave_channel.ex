defmodule ChatRoomWeb.JoinAndLeaveChannel do
  use Phoenix.Channel

  def join("example:join_and_leave_channels", %{"username" => username, "password" => password} = params, socket) do
    {:ok, params, socket}
  end

  def join("example:join_and_leave_channels", %{}, socket), do: {:ok, socket}
end