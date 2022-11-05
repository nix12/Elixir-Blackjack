defmodule Blackjack.Communications.Notifications.Notification do
  @moduledoc """
    Notification model.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Blackjack.Accounts.Inbox.InboxesNotifications

  schema "notifications" do
    field(:body, :string)
    field(:read, :boolean, default: false)
    field(:user_uuid, :binary_id)

    has_many(:inboxes_notifications, InboxesNotifications)
    has_many(:notifications, through: [:inboxes_notifications, :inbox])

    timestamps()
  end

  def changeset(notification, params \\ %{}) do
    notification
    |> cast(params, [:body, :user_uuid])
    |> validate_required([:body, :user_uuid])
  end
end
