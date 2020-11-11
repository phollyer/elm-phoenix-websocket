defmodule ChatRoomWeb.Presence do
  use Phoenix.Presence,
    otp_app: :chat_room,
    pubsub_server: ChatRoom.PubSub


  def fetch("example:lobby", presences) do
    for {key, %{metas: metas}} <- presences, into: %{} do
      case find_user(key) do
        {:ok, user} ->
          {key, %{metas: metas, user: user}}

        :not_found ->
          {key, %{metas: metas}}
      end
    end
  end

  defp find_user(id) do
    case :ets.lookup(:users_table, id) do
      [{_, user} | _] ->
        {:ok, user}

      [] ->
        :not_found
    end
  end
end