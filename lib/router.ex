defmodule LoadBalancer.Plug do
  import Plug.Conn
  require Logger

  @spec init(any) :: any
  def init(options), do: options

  @spec build_url(String.t(), String.t()) :: String.t()
  defp build_url(path, base) do
    Enum.join([base, path])
  end

  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(conn, _opts) do
    base_url = GenServer.call(:pool, :next)
    IO.inspect(Registry.lookup(Registry, :backend))
    ip = conn.remote_ip |> Tuple.to_list() |> Enum.join(".")
    headers = [{"X-Forwarded-For", ip} | conn.req_headers]

    url =
      conn
      |> request_url
      |> URI.parse()
      |> Map.get(:path)
      |> build_url(base_url)

    Logger.info("#{conn.method} #{url}")

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{body: body, headers: headers, status_code: status_code}} ->
        conn
        |> merge_resp_headers(headers)
        |> send_resp(status_code, body)
    end
  end
end
