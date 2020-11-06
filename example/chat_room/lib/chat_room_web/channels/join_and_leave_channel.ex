defmodule ChatRoomWeb.JoinAndLeaveChannel do
  use Phoenix.Channel



  def join("example:join_and_leave_channels", %{"username" => "good", "password" => "good"}, socket) do
    {:ok, %{"user_id" => "1"}, socket}
  end

  def join("example:join_and_leave_channels", %{"username" => "bad", "password" => "bad"}, socket) do
    {:error, %{"error" => "Not Authorised"}}
  end

  def join("example:join_and_leave_channels", %{}, socket), do: {:ok, socket}
end