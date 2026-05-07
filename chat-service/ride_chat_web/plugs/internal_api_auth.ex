defmodule RideChatWeb.Plugs.InternalApiAuth do
  import Plug.Conn

  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _opts) do
    expected = System.get_env("INTERNAL_API_TOKEN", "")

    cond do
      expected == "" ->
        conn

      bearer_token(conn) == expected ->
        conn

      true ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(:unauthorized, ~s({"error":"unauthorized"}))
        |> halt()
    end
  end

  defp bearer_token(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization") do
      token
    else
      _ -> ""
    end
  end
end
