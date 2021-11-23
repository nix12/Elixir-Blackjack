defmodule Blackjack.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Blackjack.Repo

      import Ecto
      import Ecto.Query
      import Blackjack.RepoCase
      import BlackjackTest.Helpers
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Blackjack.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Blackjack.Repo, {:shared, self()})
    end

    :ok
  end
end
