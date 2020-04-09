defmodule Blackjack do
  use Application

  alias Blackjack.{Application, Deck}

  def start(_type, _args) do
    IO.puts("Starting Blackjack application.")

    app =
      {:ok, pid} = Blackjack.Processes.Supervisor.start_link(name: Blackjack.Processes.Supervisor)

    Blackjack.Processes.Server.start()
    app
  end

  def start_phase(_type, _args, _) do
    Blackjack.Processes.Server.start()
  end

  def start_game(_opts) do
    IO.puts("Starting game.")

    Task.start_link(fn ->
      [players | deck] = Application.deal(Application.set_players(), Deck.build_deck(), 2, [])
      Application.main(players, deck, [])
    end)
  end
end
