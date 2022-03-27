defmodule BlackjackCli do
  require Logger

  def fetch_server(server_name) do
    %HTTPoison.Response{body: body, status_code: 200} =
      HTTPoison.get!(
        "http://localhost:#{Application.get_env(:blackjack, :port)}/server/#{server_name |> Blackjack.format_name()}",
        [{"Content-Type", "application/json"}]
      )

    Jason.decode!(body)
  end

  def fetch_servers do
    %HTTPoison.Response{body: body, status_code: 200} =
      HTTPoison.get!(
        "http://localhost:#{Application.get_env(:blackjack, :port)}/servers",
        [{"Content-Type", "application/json"}]
      )

    Jason.decode!(body)
  end

  def get_server(server_name) do
    task = Task.async(fn -> fetch_server(server_name) end)

    Task.await(task)
  end

  def get_servers do
    task = Task.async(fn -> fetch_servers() end)

    Task.await(task)
  end

  def subscribe_server(_model) do
    :timer.send_interval(5000, :gui, {:event, :subscribe_server})
  end

  def join_server(username, server_name) do
    :httpc.request(
      :post,
      {'http://localhost:#{Application.get_env(:blackjack, :port)}/server/#{server_name |> Blackjack.format_name()}/join',
       [], 'application/json', Jason.encode!(%{server_name: server_name, username: username})},
      [],
      []
    )
  end

  def leave_server(username, server_name) do
    :httpc.request(
      :post,
      {'http://localhost:#{Application.get_env(:blackjack, :port)}/server/#{server_name |> Blackjack.format_name()}/leave',
       [], 'application/json', Jason.encode!(%{server_name: server_name, username: username})},
      [],
      []
    )
  end

  # Routes
  def login_path(user_params) do
    HTTPoison.post!(
      "http://localhost:#{Application.get_env(:blackjack, :port)}/login",
      Jason.encode!(user_params),
      [{"Content-Type", "application/json"}]
    )
  end

  def register_path(user_params) do
    HTTPoison.post!(
      "http://localhost:#{Application.get_env(:blackjack, :port)}/register",
      Jason.encode!(user_params),
      [{"Content-Type", "application/json"}]
    )
  end
end
