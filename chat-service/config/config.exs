import Config

config :ride_chat,
  ecto_repos: [RideChat.Repo],
  cors_origins: ["*"]

config :ride_chat, RideChat.Auth.Guardian,
  issuer: "ride_chat",
  secret_key: System.get_env("GUARDIAN_SECRET_KEY", "ride-chat-dev-secret")

config :ride_chat, RideChat.PubSub,
  adapter: Phoenix.PubSub.PG2

config :ride_chat, RideChatWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: RideChatWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: RideChat.PubSub,
  secret_key_base:
    System.get_env(
      "SECRET_KEY_BASE",
      "ridechatdevridechatdevridechatdevridechatdevridechatdevridechatdev"
    ),
  live_view: [signing_salt: "ride-chat-live-signing-salt"]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
