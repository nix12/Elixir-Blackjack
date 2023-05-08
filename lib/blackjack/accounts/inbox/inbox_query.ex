defmodule Blackjack.Accounts.Inbox.InboxQuery do
  import Ecto.Query, only: [from: 2, subquery: 1]

  alias Blackjack.Repo
  alias Blackjack.Accounts.User
  alias Blackjack.Accounts.Inbox.Inbox
  alias Blackjack.Communications.Conversations.Conversation
  alias Blackjack.Communications.Notifications.Notification
  alias Blackjack.Communications.Messages.Message

  def read_conversations(current_user) do
    from(
      conversations in Conversation,
      join: inboxes in Inbox,
      on: inboxes.id == conversations.current_user_inbox_id,
      left_join: messages in Message,
      on: conversations.current_user_inbox_id == inboxes.id,
      where: ^current_user["id"] == inboxes.user_id,
      select: %{
        id: conversations.id,
        inserted_at: conversations.inserted_at,
        from:
          fragment(
            "SELECT CONCAT(inboxes.user_id, ': ', users.username)
             FROM inboxes
             LEFT JOIN users
             ON inboxes.user_id = users.id
             WHERE inboxes.id = ?",
            conversations.recipient_inbox_id
          ),
        messages: messages
      },
      order_by: {:desc, :inserted_at}
    )
  end

  def read_notifications(current_user) do
    from(
      notifications in Notification,
      join: inbox in Inbox,
      where: ^current_user["id"] == inbox.user_id,
      select: %{
        inserted_at: notifications.inserted_at,
        from: notifications.from
      },
      order_by: {:desc, :inserted_at}
    )
  end

  def all_communications(current_user) do
    from(
      communications in (current_user |> notifications() |> subquery()),
      join: inboxes in Inbox,
      where: ^current_user["id"] == inboxes.user_id,
      select: %{
        inserted_at: communications.inserted_at,
        from: communications.from
      },
      order_by: communications.inserted_at
    )
  end

  def conversations(current_user) do
    from(
      conversations in Conversation,
      left_join: inboxes in Inbox,
      on: inboxes.id == conversations.current_user_inbox_id,
      where: ^current_user["id"] == inboxes.user_id,
      select: %{
        inserted_at: conversations.inserted_at,
        from:
          fragment(
            "SELECT CONCAT(inboxes.user_id, ': ', users.username)
            FROM inboxes
            LEFT JOIN users
            ON inboxes.user_id = users.id
            WHERE inboxes.id = ?",
            conversations.recipient_inbox_id
          )
      }
    )
  end

  def notifications(current_user) do
    from(
      notifications in Notification,
      union: ^conversations(current_user),
      select: %{
        inserted_at: notifications.inserted_at,
        from: notifications.from
      }
    )
  end
end
