defmodule ChatRoomWeb.SimpleJoinAndLeaveChannel do
  use Phoenix.Channel

  def join("example:simple_join_and_leave", _, socket), do: {:ok, socket}
end