import Config

default_backends = "http://localhost:7001,http://localhost:7002,http://localhost:7003"

config :load_balancer,
  backend_urls: System.get_env("BACKEND_URLS", default_backends) |> String.split(","),
  healthcheck_interval: System.get_env("HEALTHCHECK_INTERVAL", "5000") |> String.to_integer
