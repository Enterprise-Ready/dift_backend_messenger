defmodule RideChatWeb.RoomChannel do
  use RideChatWeb, :channel

  alias RideChat.Chat
  alias RideChat.Chat.CallSessionRegistry
  alias RideChatWeb.Presence

  @default_call_timeout 30

  @impl true
  def join("room:" <> conversation_id, payload, socket) do
    if Chat.member?(conversation_id, socket.assigns.user_id) do
      send(self(), {:after_join, payload})

      {:ok,
       %{
         room_id: conversation_id,
         user_id: socket.assigns.user_id,
         rtc: rtc_config()
       }, assign(socket, :conversation_id, conversation_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info({:after_join, payload}, socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.user_id, %{
        online_at: inspect(System.system_time(:second)),
        role: Map.get(payload, "role", socket.assigns[:role] || "driver"),
        device_id: Map.get(payload, "device_id", socket.assigns[:device_id] || "mobile")
      })

    push(socket, "presence_state", Presence.list(socket))

    broadcast!(socket, "room:lifecycle", %{
      event: "participant_joined",
      user_id: socket.assigns.user_id,
      room_id: socket.assigns.conversation_id
    })

    {:noreply, socket}
  end

  @impl true
  def handle_in("send_msg", params, socket) do
    handle_in("message:send", params, socket)
  end

  @impl true
  def handle_in("message:send", %{"content" => content} = params, socket) do
    result =
      Chat.send_message(%{
        conversation_id: socket.assigns.conversation_id,
        sender_id: socket.assigns.user_id,
        content: content,
        type: Map.get(params, "type", "text"),
        payload: Map.get(params, "payload", %{})
      })

    case result do
      {:ok, msg} ->
        {:reply, {:ok, %{message: serialize_message(msg)}}, socket}

      {:error, _} ->
        {:reply, :error, socket}
    end
  end

  @impl true
  def handle_info({:new_msg, message}, socket) do
    push(socket, "new_msg", serialize_message(message))
    {:noreply, socket}
  end

  @impl true
  def handle_in("voice_signal", %{"data" => data, "target" => target}, socket) do
    handle_in("signal:relay", %{"data" => data, "target" => target, "kind" => "voice"}, socket)
  end

  @impl true
  def handle_in("signal:relay", %{"data" => data, "target" => target} = payload, socket) do
    broadcast_from!(socket, "signal:relay", %{
      sender_id: socket.assigns.user_id,
      target: target,
      kind: Map.get(payload, "kind", "webrtc"),
      data: data,
      timestamp: System.system_time(:second)
    })

    {:noreply, socket}
  end

  @impl true
  def handle_in("typing:update", %{"typing" => typing}, socket) do
    broadcast_from!(socket, "typing:update", %{
      user_id: socket.assigns.user_id,
      typing: typing
    })

    {:noreply, socket}
  end

  @impl true
  def handle_in("location:relay", %{"location" => location, "transport" => transport}, socket) do
    broadcast_from!(socket, "location:relay", %{
      user_id: socket.assigns.user_id,
      transport: transport,
      location: location,
      timestamp: System.system_time(:second)
    })

    {:noreply, socket}
  end

  @impl true
  def handle_in("call:ring", payload, socket) do
    timeout_seconds = parse_timeout(payload["timeout_seconds"])
    timeout_at = DateTime.add(DateTime.utc_now(), timeout_seconds, :second)

    call =
      %{
        "call_id" => Map.get(payload, "call_id", default_call_id(socket.assigns.conversation_id)),
        "room_id" => socket.assigns.conversation_id,
        "initiator_id" => socket.assigns.user_id,
        "target_id" => Map.get(payload, "target", ""),
        "mode" => Map.get(payload, "mode", "audio"),
        "state" => "ringing",
        "timeout_at" => DateTime.to_iso8601(timeout_at),
        "booking_id" => Map.get(payload, "booking_id"),
        "driver_id" => Map.get(payload, "driver_id"),
        "passenger_id" => Map.get(payload, "passenger_id")
      }

    {:ok, _session} = CallSessionRegistry.upsert(socket.assigns.conversation_id, call)
    Process.send_after(self(), {:call_timeout, call["call_id"]}, timeout_seconds * 1_000)

    broadcast!(socket, "call:incoming", call)
    broadcast!(socket, "call:lifecycle", call)

    {:reply, {:ok, %{call: call}}, socket}
  end

  @impl true
  def handle_in("call:accept", %{"call_id" => call_id}, socket) do
    with {:ok, session} <- CallSessionRegistry.get(socket.assigns.conversation_id),
         true <- session["call_id"] == call_id do
      accepted =
        session
        |> Map.put("state", "accepted")
        |> Map.put("accepted_by", socket.assigns.user_id)

      {:ok, _session} = CallSessionRegistry.upsert(socket.assigns.conversation_id, accepted)
      broadcast!(socket, "call:lifecycle", accepted)
      {:reply, {:ok, %{call: accepted}}, socket}
    else
      _ -> {:reply, {:error, %{reason: "call_not_found"}}, socket}
    end
  end

  @impl true
  def handle_in("call:reject", %{"call_id" => call_id}, socket) do
    update_call_state(socket, call_id, "rejected", %{"rejected_by" => socket.assigns.user_id})
  end

  @impl true
  def handle_in("call:end", %{"call_id" => call_id}, socket) do
    update_call_state(socket, call_id, "ended", %{"ended_by" => socket.assigns.user_id})
  end

  @impl true
  def handle_in("call:reconnect", %{"call_id" => call_id} = payload, socket) do
    extras = %{
      "reconnect_by" => socket.assigns.user_id,
      "target_id" => Map.get(payload, "target", "")
    }

    update_call_state(socket, call_id, "reconnecting", extras, false)
  end

  @impl true
  def handle_info({:call_timeout, call_id}, socket) do
    case CallSessionRegistry.get(socket.assigns.conversation_id) do
      {:ok, %{"call_id" => ^call_id, "state" => "ringing"} = session} ->
        timed_out = Map.put(session, "state", "timeout")
        {:ok, _session} = CallSessionRegistry.upsert(socket.assigns.conversation_id, timed_out)
        broadcast!(socket, "call:lifecycle", timed_out)
        CallSessionRegistry.clear(socket.assigns.conversation_id)
        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def terminate(_reason, socket) do
    broadcast!(socket, "room:lifecycle", %{
      event: "participant_left",
      user_id: socket.assigns.user_id,
      room_id: socket.assigns.conversation_id
    })

    :ok
  end

  defp update_call_state(socket, call_id, next_state, extras, clear_after \\ true) do
    with {:ok, session} <- CallSessionRegistry.get(socket.assigns.conversation_id),
         true <- session["call_id"] == call_id do
      updated =
        session
        |> Map.merge(extras)
        |> Map.put("state", next_state)

      {:ok, _session} = CallSessionRegistry.upsert(socket.assigns.conversation_id, updated)
      broadcast!(socket, "call:lifecycle", updated)

      if clear_after do
        CallSessionRegistry.clear(socket.assigns.conversation_id)
      end

      {:reply, {:ok, %{call: updated}}, socket}
    else
      _ -> {:reply, {:error, %{reason: "call_not_found"}}, socket}
    end
  end

  defp rtc_config do
    rtc = Application.get_env(:ride_chat, :rtc, [])

    %{
      ice_servers: Keyword.get(rtc, :ice_servers, [%{"urls" => ["stun:stun.l.google.com:19302"]}]),
      relay_mode: Keyword.get(rtc, :relay_mode, "auto"),
      fallback_transport: Keyword.get(rtc, :fallback_transport, "socket")
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

  defp parse_timeout(timeout) when is_integer(timeout) and timeout > 0, do: timeout
  defp parse_timeout(timeout) when is_binary(timeout) do
    case Integer.parse(timeout) do
      {value, _} when value > 0 -> value
      _ -> @default_call_timeout
    end
  end
  defp parse_timeout(_), do: @default_call_timeout

  defp default_call_id(room_id) do
    "call-#{room_id}-#{System.system_time(:millisecond)}"
  end
end
