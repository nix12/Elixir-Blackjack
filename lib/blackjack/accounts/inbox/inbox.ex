defmodule Blackjack.Accounts.Inbox do
  use Ecto.Schema

  import Ecto.Changeset

  alias Blackjack.Accounts.User
  alias Blackjack.Accounts.Inbox.Notifications.Notification
  alias Blackjack.Accounts.Inbox.InboxesNotifications
  alias Blackjack.Accounts.Inbox.Conversations.Conversation

  schema "inboxes" do
    belongs_to(:user, User, foreign_key: :user_uuid, references: :uuid, type: :binary_id)

    has_many(:inboxes_notifications, InboxesNotifications)
    has_many(:notifications, through: [:inboxes_notifications, :notification])

    has_many(:conversations, Conversation)
  end

  def changeset(inbox, params \\ %{}) do
    inbox
    |> cast(params, [])

    # Ecto.build_assoc(inbox, :notifications)
    # |> Ecto.Changeset.change(params)
  end
end
