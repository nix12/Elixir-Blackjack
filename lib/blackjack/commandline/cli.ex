# Fix player actions

defmodule Blackjack.Commandline.CLI do
  alias Blackjack.Application
  alias Blackjack.Processes.Server

  def main(_args \\ []) do
    IO.puts("Opening Blackjack")
    run()
  end

  def run do
    IO.puts("Starting Blackjack application.")

    Blackjack.Processes.Supervisor.start_link(name: Blackjack.Processes.Supervisor)

    # Blackjack.Web.Controllers.AuthenticationController.get_credentials()

    create_server()
    create_table()
    start_game()
  end

  def create_server do
    server_name =
      IO.gets("What would you like to name this server?\n")
      |> String.trim()

    Server.new_server(server_name, %{})
  end

  def create_table do
    server = IO.gets("What server would you like to join\n") |> String.trim()

    table_name =
      IO.gets("What would you like to name this table?\n")
      |> String.trim()

    Server.new_table(server, table_name)
  end

  def join_table do
    table =
      IO.gets("What table would you like to join\n")
      |> String.trim()

    IO.puts("joining table")

    Server.join_table(table, self())
  end

  def start_game do
    IO.puts("Starting game.")
    IO.puts("START GAME SELF")
    IO.inspect(self())

    Task.start_link(fn ->
      IO.puts("TASK SELF")
      IO.inspect(self())
      Process.register(self(), :game)

      Application.setup()
      Application.main()

      receive do
        :continue ->
          Application.main()

        :end ->
          System.stop(0)
      end
    end)
  end
end
