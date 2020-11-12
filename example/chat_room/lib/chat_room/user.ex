defmodule ChatRoom.User do

  alias ChatRoom.Room

  def create(username) do
    %{id: create_id(),
      username: username,
      rooms: []
    }
  end

  def find(id) do
    case :ets.lookup(:users_table, id) do
      [{_, user} | _] ->
        {:ok, user}

      [] ->
        :not_found
    end
  end

  def update(user) do
    if :ets.insert(:users_table, {user.id, user}) do
      {:ok, user}
    else
      :error
    end
  end

  def delete(user) do
    Room.delete_list(user.rooms)

   :ets.delete(:users_table, user.id)
  end

  def new_room(user, room_id), do: Map.update(user, :rooms, [room_id], &([room_id | &1]))

  def create_id(), do: inspect(rem System.system_time(:millisecond), 1_000_000)
end