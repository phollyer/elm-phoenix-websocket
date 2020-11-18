defmodule ElmPhoenixWebSocketExampleWeb.Presence do
  use Phoenix.Presence,
    otp_app: :elm_phoenix_web_socket_example,
    pubsub_server: ElmPhoenixWebSocketExample.PubSub

  alias ElmPhoenixWebSocketExample.User

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

  def fetch("example:room:" <> room_id, presences) do
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