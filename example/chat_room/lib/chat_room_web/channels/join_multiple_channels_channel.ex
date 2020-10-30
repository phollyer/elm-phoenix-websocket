defmodule ChatRoomWeb.JoinMultipleChannelsChannel do
  use Phoenix.Channel

  def join("example:join_channel_number_" <> num, _, socket), do: {:ok, socket}
end