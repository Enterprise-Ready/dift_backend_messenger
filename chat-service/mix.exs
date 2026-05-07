defmodule RideChat.MixProject do
  use Mix.Project

  def project do
    [
      app: :ride_chat,
      version: "1.0.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {RideChat.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "ride_chat", "ride_chat_web", "test/support"]
  defp elixirc_paths(_), do: ["lib", "ride_chat", "ride_chat_web"]

  defp deps do
    [
      {:phoenix, "~> 1.7.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_pubsub_redis, "~> 3.0"}, # Essential for Clustering
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:guardian, "~> 2.3"},           # JWT Authentication
      {:cors_plug, "~> 3.0"},          # Security
      {:telemetry_metrics, "~> 0.6"},  # Metrics
      {:telemetry_poller, "~> 1.0"}
    ]
  end
end
