defmodule RideChat.Chat.CallSessionRegistry do
  use GenServer

  @table :ride_chat_call_sessions

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def upsert(room_id, attrs) do
    GenServer.call(__MODULE__, {:upsert, room_id, attrs})
  end

  def get(room_id) do
    case :ets.lookup(@table, room_id) do
      [{^room_id, session}] -> {:ok, session}
      [] -> {:error, :not_found}
    end
  end

  def clear(room_id) do
    GenServer.call(__MODULE__, {:clear, room_id})
  end

  @impl true
  def init(_state) do
    :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
    {:ok, %{}}
  end

  @impl true
  def handle_call({:upsert, room_id, attrs}, _from, state) do
    session =
      case get(room_id) do
        {:ok, existing} -> Map.merge(existing, attrs)
        {:error, :not_found} -> attrs
      end

    :ets.insert(@table, {room_id, session})
    {:reply, {:ok, session}, state}
  end

  @impl true
  def handle_call({:clear, room_id}, _from, state) do
    :ets.delete(@table, room_id)
    {:reply, :ok, state}
  end
end
