defmodule ElmPhoenixWebSocketExampleWeb.PageController do
  use ElmPhoenixWebSocketExampleWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
