defmodule Blackjack.Accounts.Inbox.InboxesConversations do
  @moduledoc """
    Friendship model.
  """
  use Ecto.Schema

  alias Blackjack.Accounts.Inbox.Inbox
  alias Blackjack.Communications.Conversations.Conversation

  schema "inboxes_conversations" do
    belongs_to(:current_user_inbox, Inbox, foreign_key: :current_user_inbox_id)
    belongs_to(:recipient_inbox, Inbox, foreign_key: :recipient_inbox_id)
    belongs_to(:conversation, Conversation, foreign_key: :conversation_id)
  end
end
