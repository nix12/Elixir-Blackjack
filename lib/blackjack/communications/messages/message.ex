defmodule Blackjack.Communications.Messages.Message do
  @moduledoc """
    Message model.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Blackjack.Accounts.User
  alias Blackjack.Communications.Conversations.Conversation

  schema "messages" do
    field(:title, :string, default: "Empty.")
    field(:body, :string)
    field(:read, :boolean, default: false)

    belongs_to(:user, User, type: :binary_id)
    belongs_to(:conversation, Conversation)

    timestamps()
  end

  def changeset(message, params) do
    message
    |> cast(params, [:title, :body, :user_id, :conversation_id])
    |> validate_required([:title, :body, :user_id, :conversation_id])
  end
end
