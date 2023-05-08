defmodule Blackjack.Communications.Conversations.Conversation do
  @moduledoc """
    Conversation model.
  """
  use Ecto.Schema

  alias Blackjack.Accounts.Inbox.Inbox
  alias Blackjack.Communications.Messages.Message

  @derive {Jason.Encoder, only: [:inserted_at, :updated_at]}

  schema "conversations" do
    field(:full_recipient, :string, virtual: true)

    belongs_to(:current_user_inbox, Inbox, foreign_key: :current_user_inbox_id)
    belongs_to(:recipient_inbox, Inbox, foreign_key: :recipient_inbox_id)

    has_many(:messages, Message, on_delete: :delete_all)

    timestamps()
  end
end
