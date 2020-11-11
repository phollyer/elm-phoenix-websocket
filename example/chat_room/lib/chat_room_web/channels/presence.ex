defmodule ChatRoomWeb.Presence do
  use Phoenix.Presence,
    otp_app: :chat_room,
    pubsub_server: ChatRoom.PubSub


  def fetch("example:lobby", presences) do
    IO.puts "*****************"
    IO.inspect presences
    IO.puts "*****************"

    [{_, user} | _] =
      Map.keys(presences)
      |> Enum.fetch(0)
      |> find_user()

    for {key, %{metas: metas}} <- presences, into: %{} do
      {key, %{metas: metas, user: user}}
    end
  end

  defp find_user({:ok, id}), do: :ets.lookup(:users_table, id)
  defp find_user(:error), do: [{"", %{}}]
end