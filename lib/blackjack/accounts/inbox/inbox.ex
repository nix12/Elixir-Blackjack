defmodule Blackjack.Accounts.Inbox.Inbox do
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

  @derive {Jason.Encoder, only: [:id]}

  schema "inboxes" do
    belongs_to(:user, User, foreign_key: :user_id, type: :binary_id)

    has_many(:notifications, Notification, foreign_key: :recipient_inbox_id)
    has_many(:conversations, Conversation, foreign_key: :current_user_inbox_id)
    has_many(:recipient_conversations, Conversation, foreign_key: :recipient_inbox_id)
  end

  @doc """
    Takes inbox struct and change parameters to create a changeset.
  """
  def changeset(inbox, params) do
    inbox
    |> cast(params, [:id])
    |> validate_required([:id])
  end
end
