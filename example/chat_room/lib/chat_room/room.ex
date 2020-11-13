defmodule ChatRoom.Room do

  def create(user) do
    %{id: create_id(),
      owner: %{id: user.id, username: user.username},
      members: [],
      messages: []
    }
  end

  def find(id) do
    case :ets.lookup(:rooms_table, id) do
      [{_, room} | _] ->
        {:ok, room}

      [] ->
        :not_found
    end
  end

  def update(room) do
    if :ets.insert(:rooms_table, {room.id, room}) do
      {:ok, room}
    else
      :error
    end
  end

  def all() do
   :ets.match(:rooms_table, :"$1")
   |> Enum.concat
   |> Enum.map(fn {_, room} -> room end)
  end

  def messages(id) do
    case find(id) do
      {:ok, room} ->
        room.messages

      :not_found ->
        []
    end
  end

  def delete_list(list), do: Enum.each(list, &(:ets.delete(:rooms_table, &1)))

  def create_id(), do: inspect System.system_time(:millisecond)
end