defmodule RideChat.Chat do
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias RideChat.Repo
  alias RideChat.Chat.{Conversation, Message, ConversationMember}
  alias RideChat.Chat.CallSessionRegistry
  alias RideChat.Auth.Guardian

  # --- Internal API Logic (Called by Go Backend) ---
  
  # สร้างห้องแชทแบบ Atomic (สร้างห้อง + เพิ่มสมาชิก ต้องสำเร็จพร้อมกัน)
  def create_booking_room(booking_id, driver_id, passenger_id) do
    Multi.new()
    |> Multi.insert(:conversation, Conversation.changeset(%Conversation{}, %{booking_id: booking_id}))
    |> Multi.run(:members, fn repo, %{conversation: conv} ->
         insert_members(repo, conv.id, [driver_id, passenger_id])
       end)
    |> Repo.transaction()
  end

  def ensure_booking_room(booking_id, driver_id, passenger_id) do
    case Repo.get_by(Conversation, booking_id: booking_id) do
      nil ->
        create_booking_room(booking_id, driver_id, passenger_id)

      conversation ->
        {:ok, %{conversation: conversation}}
    end
  end

  def resolve_room(room_hint, booking_id, driver_id, passenger_id) do
    cond do
      present?(room_hint) ->
        case Repo.get(Conversation, room_hint) do
          %Conversation{} = conversation -> {:ok, %{conversation: conversation}}
          nil -> {:error, :not_found}
        end

      present?(booking_id) ->
        ensure_booking_room(booking_id, driver_id, passenger_id)

      true ->
        {:error, :bad_request}
    end
  end

  def lookup_room(room_hint, booking_id, driver_id, passenger_id, user_id) do
    with {:ok, %{conversation: room}} <- resolve_room(room_hint, booking_id, driver_id, passenger_id),
         true <- member?(room.id, user_id),
         {:ok, bootstrap} <- room_bootstrap(room.id, user_id) do
      {:ok, room, bootstrap}
    else
      false -> {:error, :unauthorized}
      {:error, reason} -> {:error, reason}
    end
  end

  defp insert_members(repo, conv_id, user_ids) do
    timestamp = DateTime.utc_now()
    entries = Enum.map(user_ids, fn uid -> 
      %{conversation_id: conv_id, user_id: uid, inserted_at: timestamp, updated_at: timestamp}
    end)
    {count, _} = repo.insert_all(ConversationMember, entries)
    {:ok, count}
  end

  # --- User Action Logic ---

  # ตรวจสอบสิทธิ์ว่า User อยู่ในห้องนี้จริงไหม
  def member?(conversation_id, user_id) do
    Repo.exists?(from m in ConversationMember, 
      where: m.conversation_id == ^conversation_id and m.user_id == ^user_id)
  end

  def get_room(conversation_id) do
    Conversation
    |> Repo.get(conversation_id)
    |> Repo.preload([:members, messages: from(m in Message, order_by: [asc: m.inserted_at], limit: 50)])
  end

  def list_members(conversation_id) do
    from(m in ConversationMember, where: m.conversation_id == ^conversation_id)
    |> Repo.all()
  end

  def issue_session_token(user_id, role, conversation_id, device_id, extra_claims \\ %{}) do
    claims =
      extra_claims
      |> Map.put("role", role)
      |> Map.put("room_id", conversation_id)
      |> Map.put("device_id", device_id)

    Guardian.encode_and_sign(user_id, claims, ttl: {12, :hour})
  end

  def room_bootstrap(conversation_id, user_id) do
    with true <- member?(conversation_id, user_id),
         %Conversation{} = room <- get_room(conversation_id) do
      {:ok,
       %{
         room: room,
         members: Enum.map(room.members, &serialize_member/1),
         messages: Enum.map(room.messages, &serialize_message/1),
         active_call: active_call(conversation_id)
       }}
    else
      false -> {:error, :unauthorized}
      nil -> {:error, :not_found}
    end
  end

  def active_call(conversation_id) do
    case CallSessionRegistry.get(conversation_id) do
      {:ok, session} -> session
      {:error, :not_found} -> nil
    end
  end

  # ส่งข้อความและ Broadcast
  def send_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, message} ->
        # Broadcast Event ไปที่ Redis PubSub
        Phoenix.PubSub.broadcast(RideChat.PubSub, "room:#{message.conversation_id}", {:new_msg, message})
        {:ok, message}
      error -> error
    end
  end

  def list_messages(conversation_id, limit \\ 50) do
    from(m in Message,
      where: m.conversation_id == ^conversation_id,
      order_by: [desc: m.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  defp serialize_member(member) do
    %{
      id: member.id,
      user_id: member.user_id,
      inserted_at: member.inserted_at
    }
  end

  defp serialize_message(message) do
    %{
      id: message.id,
      content: message.content,
      sender_id: message.sender_id,
      type: message.type,
      payload: message.payload,
      inserted_at: message.inserted_at
    }
  end

  defp present?(value), do: is_binary(value) and String.trim(value) != ""
end

