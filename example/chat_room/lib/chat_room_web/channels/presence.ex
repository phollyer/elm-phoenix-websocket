defmodule ChatRoomWeb.Presence do
  use Phoenix.Presence,
    otp_app: :chat_room,
    pubsub_server: ChatRoom.PubSub


  def fetch("example:lobby", presences) do
    get_id =
      Map.keys(presences)
      |> Enum.fetch(0)

    [{_, user} | _] =
      case get_id do
        {:ok, id} ->
          :ets.lookup(:users_table, id)
        :error ->
          [{"", %{}}]
      end

    for {key, %{metas: metas}} <- presences, into: %{} do
      {key, %{metas: metas, user: user}}
    end
  end
end