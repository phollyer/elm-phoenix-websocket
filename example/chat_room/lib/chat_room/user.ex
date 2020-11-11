defmodule ChatRoom.User do


  def find(id) do
    case :ets.lookup(:users_table, id) do
      [{_, user} | _] ->
        {:ok, user}

      [] ->
        :not_found
    end
  end
end