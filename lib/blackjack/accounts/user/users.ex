defmodule Blackjack.Accounts.Users do
  @moduledoc """
    Contains functions that support actions in the user manager friendships.
  """
  alias Blackjack.Repo
  alias Blackjack.Accounts.Inbox.InboxesConversations

  def insert_conversation_into_inboxes(current_user, requested_user, conversation) do
    current_user_inbox_changeset = %InboxesConversations{
      inbox: current_user |> Repo.preload(:inbox) |> Map.get(:inbox),
      conversation: conversation
    }

    requested_user_inbox_changeset = %InboxesConversations{
      inbox: requested_user |> Repo.preload(:inbox) |> Map.get(:inbox),
      conversation: conversation
    }

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:current_user_inbox, current_user_inbox_changeset)
    |> Ecto.Multi.insert(:requested_user_inbox, requested_user_inbox_changeset)
    |> Repo.transaction()
  end
end
