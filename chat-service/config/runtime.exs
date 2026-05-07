import Config

parse_csv = fn value ->
  value
  |> String.split(",", trim: true)
  |> Enum.map(&String.trim/1)
  |> Enum.reject(&(&1 == ""))
end

build_ice_servers = fn ->
  json = System.get_env("RTC_ICE_SERVERS_JSON", "")

  cond do
    json != "" ->
      Jason.decode!(json)

    true ->
      stun_urls =
        System.get_env("RTC_STUN_URLS", "stun:stun.l.google.com:19302")
        |> parse_csv.()

      turn_urls =
        System.get_env("RTC_TURN_URLS", "")
        |> parse_csv.()

      turn_username = System.get_env("RTC_TURN_USERNAME", "")
      turn_credential = System.get_env("RTC_TURN_CREDENTIAL", "")

      base =
        if stun_urls == [] do
          []
        else
          [%{"urls" => stun_urls}]
        end

      if turn_urls == [] do
        base
      else
        base ++
          [
            %{
              "urls" => turn_urls,
              "username" => turn_username,
              "credential" => turn_credential
            }
          ]
      end
  end
end

if config_env() == :prod do
  host = System.get_env("PHX_HOST", "chat.yourcompany.com")
  port = String.to_integer(System.get_env("PORT", "4000"))
  redis_host = System.get_env("REDIS_HOST", "localhost")
  database_url = System.fetch_env!("DATABASE_URL")
  secret_key_base = System.fetch_env!("SECRET_KEY_BASE")
  check_origin = System.get_env("CHECK_ORIGIN", "https://driver.app.com,https://passenger.app.com")
  cors_origins = System.get_env("CORS_ORIGINS", "https://driver.app.com,https://passenger.app.com")

  check_origin_list =
    check_origin
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)

  cors_origin_list =
    cors_origins
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)

  config :ride_chat, :cors_origins, cors_origin_list
  ice_servers = build_ice_servers.()
  relay_mode =
    case System.get_env("RTC_FORCE_TURN", "false") do
      "true" -> "relay"
      _ -> System.get_env("RTC_RELAY_MODE", "auto")
    end

  config :ride_chat, :rtc,
    ice_servers: ice_servers,
    relay_mode: relay_mode,
    fallback_transport: System.get_env("RTC_FALLBACK_TRANSPORT", "socket")

  config :ride_chat, RideChatWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base,
    check_origin: check_origin_list,
    force_ssl: [rewrite_on: [:x_forwarded_proto]]

  config :ride_chat, RideChat.PubSub,
    host: redis_host,
    node_name: System.get_env("NODE_NAME", "ride-chat-1")

  config :ride_chat, RideChat.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE", "20")),
    queue_target: String.to_integer(System.get_env("DB_QUEUE_TARGET_MS", "5000")),
    queue_interval: String.to_integer(System.get_env("DB_QUEUE_INTERVAL_MS", "1000")),
    ssl: System.get_env("DB_SSL", "false") == "true"
end
