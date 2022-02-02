defmodule BlackjackCli do
  require Logger

  def fetch_server(server_name) do
    {:ok, {_, _, server}} =
      :httpc.request(
        "http://localhost:#{Application.get_env(:blackjack, :port)}/server/#{server_name |> Blackjack.format_name()}"
      )

    Jason.decode!(server)
  end

  def fetch_servers do
    {:ok, {_, _, servers}} =
      :httpc.request('http://localhost:#{Application.get_env(:blackjack, :port)}/servers')

    Jason.decode!(servers)
  end

  def get_server(server_name) do
    task = Task.async(fn -> fetch_server(server_name) end)

    [Task.await(task)]
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
end
