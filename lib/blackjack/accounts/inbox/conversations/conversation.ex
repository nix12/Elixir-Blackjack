defmodule Blackjack.Accounts.Inbox.Conversations.Conversation do
  use Ecto.Schema

  alias Blackjack.Accounts.Inbox

  schema "conversations" do
    belongs_to(:inboxes, Inbox, foreign_key: :inbox_id)
  end
end
