defmodule LoadBalancer.Pool.State do
  defstruct index: -1, healthy: [], unhealthy: []
end

defmodule LoadBalancer.Pool do
  use GenServer
  require Logger

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: :pool)
  end

  @spec init(any) :: {:ok, LoadBalancer.Pool.State.t()}
  def init(backends) do
    Logger.info("Starting pool!")

    {:ok,
     %LoadBalancer.Pool.State{
       unhealthy: [],
       healthy: backends,
       index: 0
     }}
  end

  def handle_call(:next, _, %{healthy: servers, index: index}) do
    new_index = rem(index + 1, length(servers))
    {:reply, Enum.at(servers, index), %{healthy: servers, index: new_index}}
  end

  # def handle_cast(:add_backend, url, %{healthy: healthy}) do
  #   {:noreply, %{servers: [url | healthy]}}
  # end
end
