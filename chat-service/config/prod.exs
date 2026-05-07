import Config

config :ride_chat, RideChatWeb.Endpoint,
  server: true,
  cache_static_manifest: "priv/static/cache_manifest.json"

config :ride_chat, RideChatWeb.Endpoint,
  pubsub_server: RideChat.PubSub

config :ride_chat, RideChat.PubSub,
  adapter: Phoenix.PubSub.Redis

config :ride_chat, RideChat.Auth.Guardian,
  issuer: "ride_chat",
  secret_key: System.get_env("GUARDIAN_SECRET_KEY", "ride-chat-prod-secret")
