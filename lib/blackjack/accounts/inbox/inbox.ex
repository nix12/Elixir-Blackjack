defmodule Blackjack.Accounts.Inbox do
  @moduledoc """
    Inbox model.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Blackjack.Accounts.User
  alias Blackjack.Accounts.Inbox.InboxesNotifications
  alias Blackjack.Communications.Conversations.Conversation

  @type inbox :: %{
          user: map(),
          notifications: maybe_improper_list(),
          conversations: maybe_improper_list()
        }

  schema "inboxes" do
    belongs_to(:user, User,
      foreign_key: :user_uuid,
      references: :uuid,
      type: :binary_id
    )

    has_many(:inboxes_notifications, InboxesNotifications)
    has_many(:notifications, through: [:inboxes_notifications, :notification])

    has_many(:conversations, Conversation)
  end

  @doc """
    Takes inbox struct and change parameters to create a changeset.
  """
  @spec changeset(inbox()) :: Ecto.Changeset.t()
  def changeset(inbox, params \\ %{}) do
    inbox
    |> cast(params, [:user_uuid])
    |> validate_required([:user_uuid])
  end
end
