defmodule LoadBalancer.HealthCheck.State do
  defstruct state: :healthy, url: nil
end

defmodule LoadBalancer.HealthCheck do
  use GenServer
  require Logger

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end

  @spec init(any) :: {:ok, LoadBalancer.HealthCheck.State.t()}
  def init(url) do
    Logger.info("Starting healthcheck!")

    schedule()

    {:ok,
     %LoadBalancer.HealthCheck.State{
       state: :healthy,
       url: url
     }}
  end

  def handle_info(:work, s) do
    url = Map.get(s, :url)
    schedule()

    Logger.info("Healthchecking backend: #{url}")

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: status}} ->
        {:noreply, %{s | state: if(status == 200, do: :healthy, else: :unhealthy)}}

      _ ->
        {:noreply, %{s | state: :unhealthy}}
    end
  end

  defp schedule do
    # 2 seconds
    Process.send_after(self(), :check, 1000 * 2)
  end
end
