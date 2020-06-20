defmodule ChatRoomWeb.Presence do
  use Phoenix.Presence,
    otp_app: :chat_room,
    pubsub_server: ChatRoom.PubSub
end