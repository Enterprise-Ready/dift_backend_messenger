defmodule RideChatWeb.FallbackController do
  use RideChatWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: RideChatWeb.ErrorJSON)
    |> render(:"422", changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: RideChatWeb.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:error, _}) do
    conn
    |> put_status(:internal_server_error)
    |> json(%{error: "internal_server_error"})
  end
end