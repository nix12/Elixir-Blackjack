defmodule Blackjack.Accounts.Inbox do
  @moduledoc """
    Inbox model.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Blackjack.Accounts.User
  alias Blackjack.Accounts.Inbox.{InboxesNotifications, InboxesConversations}
  alias Blackjack.Communications.Conversations.Conversation
  alias Blackjack.Communications.Notifications.Notification

  @type inbox :: %{
          user: map(),
          notifications: maybe_improper_list(),
          conversations: maybe_improper_list()
        }

  @derive {Jason.Encoder, only: [:user_id]}

  schema "inboxes" do
    field(:communications, {:array, :map}, virtual: true)

    belongs_to(:user, User,
      foreign_key: :user_id,
      references: :id,
      type: :binary_id
    )

    many_to_many(:notifications, Notification,
      join_through: InboxesNotifications,
      join_keys: [inbox_id: :id, notification_id: :id]
    )

    many_to_many(:conversations, Conversation,
      join_through: InboxesConversations,
      join_keys: [inbox_id: :id, conversation_id: :id]
    )
  end

  @doc """
    Takes inbox struct and change parameters to create a changeset.
  """
  def changeset(inbox, params) do
    inbox
    |> cast(params, [:user_id])
    |> validate_required([:user_id])
  end
end
