defmodule RideChatWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      summary("phoenix.endpoint.stop.duration", unit: {:native, :millisecond}),
      summary("phoenix.router_dispatch.stop.duration", tags: [:route], unit: {:native, :millisecond}),
      summary("ride_chat.repo.query.total_time", unit: {:native, :millisecond}),
      summary("vm.memory.total", unit: {:byte, :kilobyte})
    ]
  end

  defp periodic_measurements do
    [
      {__MODULE__, :dispatch_vm_metrics, []}
    ]
  end

  def dispatch_vm_metrics do
    :telemetry.execute([:vm, :memory], %{total: :erlang.memory(:total)}, %{})
  end
end
