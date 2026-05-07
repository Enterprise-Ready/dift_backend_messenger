import Config

config :ride_chat, RideChat.Repo,
  username: System.get_env("DB_USERNAME", "postgres"),
  password: System.get_env("DB_PASSWORD", "postgres"),
  hostname: System.get_env("DB_HOST", "localhost"),
  database: System.get_env("DB_NAME", "ride_chat_test"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :ride_chat, RideChatWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "ride-chat-test-secret",
  server: false
