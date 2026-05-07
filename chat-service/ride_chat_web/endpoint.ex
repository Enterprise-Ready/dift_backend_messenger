defmodule RideChatWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :ride_chat

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_ride_chat_key",
    signing_salt: "ride-chat-signing-salt",
    same_site: "Lax",
    secure: true,
    http_only: true
  ]

  # เชื่อมต่อ Socket ที่เราเขียนไว้ (UserSocket)
  socket "/socket", RideChatWeb.UserSocket,
    websocket: true,
    longpoll: false

  # Serve at "/" the static files from "priv/static" directory.
  plug Plug.Static,
    at: "/",
    from: :ride_chat,
    gzip: false,
    only: RideChatWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :ride_chat
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  
  # สำคัญมาก: CORS Plug เพื่อให้ Frontend/App เรียก API ข้าม Domain ได้
  plug CORSPlug,
    origin: Application.compile_env(:ride_chat, :cors_origins, []),
    credentials: true,
    max_age: 86_400

  plug RideChatWeb.Router
end
