defmodule LoadBalancer.HealthCheck.State do
  defstruct url: nil, uptime: 0
end

defmodule LoadBalancer.HealthCheck do
  use GenServer
  require Logger

  @interval Application.get_env(:load_balancer, :healthcheck_interval)

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end

  def init(url: url) do
    Logger.info("Starting backend!")

    state = %LoadBalancer.HealthCheck.State{url: url}

    {:ok, state, {:continue, :initial_healthcheck}}
  end

  def handle_continue(:initial_healthcheck, state) do
    Logger.info("Doing initial healthcheck on #{state.url}")

    case healthcheck(state) do
      {:ok, _status} ->
        schedule()
        Registry.register(Registry, :backend, state.url)
        {:noreply, %{state | uptime: state.uptime + 1}}

      {:fail, reason} ->
        Logger.info("Could not initialize backend: #{reason}")
        {:stop, :initial_healthcheck_failed}
    end
  end

  def handle_info(:healthcheck, s) do
    url = Map.get(s, :url)
    schedule()

    Logger.info("Healthchecking backend: #{url}")

    case healthcheck(s) do
      {:ok, _status} ->
        {:noreply, %{s | uptime: s.uptime + 1}}

      {:fail, reason} ->
        Logger.info("Healthcheck failed with reason: #{reason}")
        {:stop, :healthcheck_failed}
    end
  end

  @spec healthcheck(LoadBalancer.HealthCheck.State.t()) ::
          {:fail, atom()} | {:ok, [{:status, integer}, ...]}
  def healthcheck(state) do
    case HTTPoison.get(state.url) do
      {:ok, %HTTPoison.Response{status_code: status}} ->
        {:ok, status: status}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:fail, reason}
    end
  end

  defp schedule do
    # 1 second
    Process.send_after(self(), :healthcheck, @interval)
  end
end
