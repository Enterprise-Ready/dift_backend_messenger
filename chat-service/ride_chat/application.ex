defmodule RideChat.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RideChat.Repo,
      RideChatWeb.Telemetry,
      RideChat.Chat.CallSessionRegistry,
      {Phoenix.PubSub, name: RideChat.PubSub}, # Start PubSub
      RideChatWeb.Presence,                    # Start Presence
      RideChatWeb.Endpoint                     # Start Web Server
    ]

    opts = [strategy: :one_for_one, name: RideChat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    RideChatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
