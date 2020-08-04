defmodule LoadBalancer do
  use Application
  require Logger

  def start(_type, _args) do
    backends = ["http://localhost:7001", "http://localhost:7002", "http://localhost:7003"]

    healthchecks =
      Enum.map(backends, fn url ->
        Supervisor.child_spec({LoadBalancer.HealthCheck, url: url}, id: url)
      end)

    registry = {Registry, [keys: :duplicate, name: Registry]}

    Supervisor.start_link([registry | healthchecks],
      strategy: :one_for_one,
      name: LoadBalancer.HealthCheckSupervisor
    )

    children = [
      {
        Plug.Cowboy,
        scheme: :http,
        plug: LoadBalancer.Plug,
        options: [
          port: 1234
        ]
      },
      {LoadBalancer.Pool, backends}
    ]

    Logger.info("Starting!")

    Supervisor.start_link(children, strategy: :one_for_one, name: LoadBalancer.Supervisor)
  end
end
