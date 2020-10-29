defmodule ChatRoomWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "example:manage_channel_messages", ChatRoomWeb.ManageChannelMessagesChannel
  channel "example:manage_presence_messages", ChatRoomWeb.ManagePresenceMessagesChannel
  channel "example:join_and_leave_channels", ChatRoomWeb.JoinAndLeaveChannel
  channel "example_controller:*", ChatRoomWeb.ExampleControllerChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @impl true
  def connect(%{"good_params" => "true"}, socket, _connect_info), do: {:ok, socket}
  def connect(%{"good_params" => "false"}, socket, _connect_info), do: :error
  def connect(_params, socket, _connect_info), do: {:ok, socket}

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     ChatRoomWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(_socket), do: nil
end
