defmodule Blackjack.Communications.Conversations.Conversation do
  @moduledoc """
    Conversation model.
  """
  use Ecto.Schema

  alias Blackjack.Accounts.Inbox

  schema "conversations" do
    belongs_to(:inbox, Inbox, foreign_key: :inbox_id)
  end
end
