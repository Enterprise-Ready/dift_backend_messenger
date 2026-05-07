defmodule RideChat.Repo do
  use Ecto.Repo,
    otp_app: :ride_chat,
    adapter: Ecto.Adapters.Postgres
end
