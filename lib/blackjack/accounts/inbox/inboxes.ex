defmodule Blackjack.Accounts.Inbox.Inboxes do
  @moduledoc """
    Contains functions for working with a users inbox.
  """
  alias Blackjack.Repo

  def create_inbox(user) do
    Ecto.build_assoc(user, :inbox) |> Repo.insert()
  end
end
