defmodule ElmPhoenixWebSocketExample.Message do

  def create(message, user) do
    %{text: message,
      owner: user,
      created_at: System.system_time(:millisecond)
    }
  end
end