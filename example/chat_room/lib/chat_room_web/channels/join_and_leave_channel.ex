defmodule ChatRoomWeb.JoinAndLeaveChannel do
  use Phoenix.Channel

  def join("example:join_and_leave_channels", %{"username" => "bad", "password" => "wrong"} = params, socket) do
    {:error, %{"error" => "Not Authorised"}}
  end

  def join("example:join_and_leave_channels", %{"username" => username, "password" => password} = params, socket) do
    {:ok, %{"user_id" => "1"}, socket}
  end

  def join("example:join_and_leave_channels", %{}, socket), do: {:ok, socket}
end