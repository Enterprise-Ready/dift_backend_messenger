defmodule RideChatWeb.UserSocket do
  use Phoenix.Socket

  alias RideChat.Auth.Guardian

  channel "room:*", RideChatWeb.RoomChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case Guardian.decode_and_verify(token) do
      {:ok, claims} ->
        socket =
          socket
          |> assign(:user_id, claims["sub"])
          |> assign(:role, claims["role"])
          |> assign(:device_id, claims["device_id"])
          |> assign(:room_id, claims["room_id"])
          |> assign(:joined_at, System.system_time(:second))

        {:ok, socket}

      {:error, _} ->
        :error
    end
  end

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end
