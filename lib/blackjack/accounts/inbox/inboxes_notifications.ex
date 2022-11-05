defmodule Blackjack.Accounts.Inbox.InboxesNotifications do
  @moduledoc """
    Friendship model.
  """
  use Ecto.Schema

  alias Blackjack.Accounts.Inbox
  alias Blackjack.Communications.Notifications.Notification

  schema "inboxes_notifications" do
    belongs_to(:inbox, Inbox)
    belongs_to(:notification, Notification)
  end
end
