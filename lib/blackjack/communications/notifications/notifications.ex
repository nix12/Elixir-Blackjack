defmodule Blackjack.Communications.Notifications.Notifications do
  alias Blackjack.Repo
  alias Blackjack.Accounts.User
  alias Blackjack.Accounts.Inbox.Inbox
  alias Blackjack.Communications.Notifications.Notification

  def create_notification(notification) do
    Notification.changeset(%Notification{}, notification) |> Repo.insert()
  end

  def send_notification(%Notification{} = notification) do
    User
    |> Repo.all()
    |> Stream.each(fn user ->
      inbox =
        Repo.get_by(Inbox, user_id: user.id)
        |> Repo.preload(:notifications)

      inbox
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:notifications, [notification | inbox.notifications])
      |> Repo.update!()
    end)
    |> Enum.to_list()
  end
end
