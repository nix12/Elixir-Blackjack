defmodule Blackjack.Communications.Messages.Message do
  @moduledoc """
    Message model.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Blackjack.Accounts.User
  alias Blackjack.Communications.Conversations.Conversation

  @derive {Jason.Encoder, only: [:inserted_at, :body, :read]}

  schema "messages" do
    field(:body, :string)
    field(:read, :boolean, default: false)

    belongs_to(:user, User, foreign_key: :user_id, type: :binary_id)
    belongs_to(:conversation, Conversation)

    timestamps()
  end

  def changeset(message, params) do
    message
    |> cast(params, [:body, :user_id, :conversation_id])
    |> validate_required([:body, :user_id, :conversation_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:conversation_id)
  end
end
