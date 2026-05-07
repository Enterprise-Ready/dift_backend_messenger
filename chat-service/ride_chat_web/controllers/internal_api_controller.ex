defmodule RideChatWeb.InternalApiController do
  use RideChatWeb, :controller
  alias RideChat.Chat

  action_fallback RideChatWeb.FallbackController

  # POST /api/internal/rooms (Called by Go Backend)
  def create_room(conn, %{"booking_id" => bid, "driver_id" => did, "passenger_id" => pid}) do
    with {:ok, %{conversation: conversation}} <- Chat.create_booking_room(bid, did, pid) do
      conn
      |> put_status(:created)
      |> json(%{status: "success", room_id: conversation.id})
    end
  end
end