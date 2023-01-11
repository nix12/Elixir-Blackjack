defmodule Blackjack.Accounts.Inbox.InboxQuery do
  import Ecto.Query, only: [from: 2, subquery: 1]

  alias Blackjack.Repo
  alias Blackjack.Accounts.Inbox
  alias Blackjack.Communications.Conversations.Conversation
  alias Blackjack.Communications.Notifications.Notification

  def read_conversations(current_user) do
    current_user
    |> Repo.preload(inbox: [conversations: :messages])
    |> get_in([
      Access.key(:inbox),
      Access.key(:conversations),
      Access.all(),
      Access.key(:messages)
    ])
    |> List.flatten()
    |> Enum.map(fn message ->
      message
      |> Map.take([:title, :body])
      |> Map.put(:from, message.user_id)
      |> Map.put(:received, message.inserted_at)
    end)
  end

  def read_notifications(current_user) do
    current_user
    |> Repo.preload(inbox: :notifications)
    |> get_in([
      Access.key(:inbox),
      Access.key(:notifications)
    ])
    |> List.flatten()
    |> Enum.map(fn notification ->
      notification
      |> Map.take([:body])
      |> Map.put(:from, "System")
      |> Map.put(:received, notification.inserted_at)
    end)
  end

  def read_all(current_user) do
    current_user |> all_messages |> Repo.all()
  end

  def all_messages(current_user) do
    from(
      inbox in Inbox,
      join: conversations in assoc(inbox, :conversations),
      on: ^current_user.id == conversations.user_id,
      join: notifications in assoc(inbox, :notifications),
      on: ^current_user.id == notifications.user_id,
      where: inbox.user_id == ^current_user.id,
      preload: [[conversations: :messages], :notifications]
    )
  end
end
