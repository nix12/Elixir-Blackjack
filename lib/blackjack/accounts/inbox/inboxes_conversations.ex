defmodule Blackjack.Accounts.Inbox.InboxesConversations do
  @moduledoc """
    Friendship model.
  """
  use Ecto.Schema

  alias Blackjack.Accounts.Inbox
  alias Blackjack.Communications.Conversations.Conversation

  schema "inboxes_conversations" do
    belongs_to(:inbox, Inbox)
    belongs_to(:conversation, Conversation)
  end
end
