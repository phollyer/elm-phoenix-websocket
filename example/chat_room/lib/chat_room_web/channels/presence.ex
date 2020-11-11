defmodule ChatRoomWeb.Presence do
  use Phoenix.Presence,
    otp_app: :chat_room,
    pubsub_server: ChatRoom.PubSub

  alias ChatRoom.User

  def fetch("example:lobby", presences) do
    for {key, %{metas: metas}} <- presences, into: %{} do
      case User.find(key) do
        {:ok, user} ->
          {key, %{metas: metas, user: user}}

        :not_found ->
          {key, %{metas: metas}}
      end
    end
  end

  def fetch(_topic, presences) do
    for {key, %{metas: metas}} <- presences, into: %{} do
      {key, %{metas: metas}}
    end
  end
end