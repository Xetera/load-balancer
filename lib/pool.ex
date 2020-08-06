defmodule LoadBalancer.Pool.State do
  defstruct index: -1
end

defmodule LoadBalancer.Pool do
  use GenServer
  require Logger

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: :pool)
  end

  @spec init(any()) :: {:ok, LoadBalancer.Pool.State.t()}
  def init(_args) do
    Logger.info("Starting pool!")

    {:ok, %LoadBalancer.Pool.State{index: 0}}
  end

  def handle_call(:next, _, %{index: index}) do
    servers = Registry.lookup(Registry, :backend)
    {_pid, url} = Enum.at(servers, index)
    new_index = rem(index + 1, length(servers))
    {:reply, url, %{index: new_index}}
  end
end
