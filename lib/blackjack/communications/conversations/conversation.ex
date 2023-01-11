defmodule Blackjack.Communications.Conversations.Conversation do
  @moduledoc """
    Conversation model.
  """
  use Ecto.Schema

  alias Blackjack.Accounts.User
  alias Blackjack.Communications.Messages.Message

  Ja

  schema "conversations" do
    belongs_to(:user, User, foreign_key: :user_id, type: :binary_id)
    belongs_to(:recipient, User, foreign_key: :recipient_id, type: :binary_id)

    has_many(:messages, Message)

    timestamps()
  end
end
