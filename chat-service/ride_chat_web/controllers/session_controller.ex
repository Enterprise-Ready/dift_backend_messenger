defmodule RideChatWeb.SessionController do
  use RideChatWeb, :controller

  alias RideChat.Chat
  alias RideChatWeb.Presence

  action_fallback RideChatWeb.FallbackController

  def create(conn, params) do
    booking_id = Map.get(params, "booking_id")
    driver_id = Map.get(params, "driver_id")
    passenger_id = Map.get(params, "passenger_id")
    room_hint = Map.get(params, "room_hint")
    user_id = Map.get(params, "user_id")
    role = Map.get(params, "role", "driver")
    device_id = Map.get(params, "device_id", "mobile")

    with {:ok, %{conversation: room}} <- Chat.resolve_room(room_hint, booking_id, driver_id, passenger_id),
         {:ok, token, _claims} <- Chat.issue_session_token(user_id, role, room.id, device_id),
         {:ok, bootstrap} <- Chat.room_bootstrap(room.id, user_id) do
      json(conn, %{
        status: "success",
        token: token,
        socket_path: "/socket/websocket",
        room_id: room.id,
        rtc: rtc_config(),
        fallback: fallback_config(room.id),
        bootstrap: Map.put(bootstrap, :presence, Presence.list("room:#{room.id}"))
      })
    end
  end

  def show(conn, %{"id" => room_id, "user_id" => user_id}) do
    with {:ok, bootstrap} <- Chat.room_bootstrap(room_id, user_id) do
      json(conn, %{
        status: "success",
        room_id: room_id,
        rtc: rtc_config(),
        fallback: fallback_config(room_id),
        bootstrap: Map.put(bootstrap, :presence, Presence.list("room:#{room_id}"))
      })
    end
  end

  def lookup(conn, params) do
    room_hint = Map.get(params, "room_hint")
    booking_id = Map.get(params, "booking_id")
    driver_id = Map.get(params, "driver_id")
    passenger_id = Map.get(params, "passenger_id")
    user_id = Map.get(params, "user_id")

    with {:ok, room, bootstrap} <- Chat.lookup_room(room_hint, booking_id, driver_id, passenger_id, user_id) do
      json(conn, %{
        status: "success",
        room_id: room.id,
        rtc: rtc_config(),
        fallback: fallback_config(room.id),
        bootstrap: Map.put(bootstrap, :presence, Presence.list("room:#{room.id}"))
      })
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

  defp fallback_config(room_id) do
    %{
      transport: "phoenix_channel",
      transports: [
        %{
          type: "phoenix_channel",
          topic: "room:#{room_id}",
          events: %{
            text: "message:send",
            signal: "signal:relay",
            typing: "typing:update",
            location: "location:relay",
            call_ring: "call:ring",
            call_accept: "call:accept",
            call_reject: "call:reject",
            call_end: "call:end",
            call_reconnect: "call:reconnect"
          }
        },
        %{
          type: "mqtt",
          topic_prefix: "chat/room/#{room_id}",
          events: %{
            text: "chat/message",
            location: "chat/location",
            signal: "chat/signal"
          }
        }
      ]
    }
  end
end

