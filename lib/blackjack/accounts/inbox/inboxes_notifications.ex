defmodule Blackjack.Accounts.Inbox.InboxesNotifications do
  use Ecto.Schema

  alias Blackjack.Accounts.Inbox
  alias Blackjack.Accounts.Inbox.Notifications.Notification

  schema "inboxes_notifications" do
    belongs_to(:inbox, Inbox)
    belongs_to(:notification, Notification)
  end
end
