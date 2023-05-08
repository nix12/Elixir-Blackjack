defmodule Blackjack.Communications.Conversations.Conversations do
  alias Blackjack.Repo
  alias Blackjack.Accounts.Inbox.Inbox
  alias Blackjack.Accounts.Inbox.InboxesConversations
  alias Blackjack.Communications.Conversations.Conversation

  def create_or_continue_conversation(current_user, requested_user) do
    current_user_inbox = Repo.get_by!(Inbox, user_id: current_user.id)
    requested_user_inbox = Repo.get_by!(Inbox, user_id: requested_user.id)

    Ecto.Multi.new()
    |> Ecto.Multi.run(:get_current_user_conversation, fn _repo, _changes ->
      {:ok,
       Repo.get_by(InboxesConversations,
         current_user_inbox_id: current_user_inbox.id,
         recipient_inbox_id: requested_user_inbox.id
       ) ||
         %Conversation{}}
    end)
    |> Ecto.Multi.insert_or_update(:current_user_conversation, fn %{
                                                                    get_current_user_conversation:
                                                                      current_user_conversation
                                                                  } ->
      Ecto.Changeset.change(current_user_conversation, %{
        current_user_inbox_id: current_user_inbox.id,
        recipient_inbox_id: requested_user_inbox.id
      })
    end)
    |> Ecto.Multi.run(:get_recipient_conversation, fn _repo, _changes ->
      {:ok,
       Repo.get_by(InboxesConversations,
         current_user_inbox_id: requested_user_inbox.id,
         recipient_inbox_id: current_user_inbox.id
       ) ||
         %Conversation{}}
    end)
    |> Ecto.Multi.insert_or_update(:recipient_conversation, fn %{
                                                                 get_recipient_conversation:
                                                                   recipient_conversation
                                                               } ->
      Ecto.Changeset.change(recipient_conversation, %{
        current_user_inbox_id: requested_user_inbox.id,
        recipient_inbox_id: current_user_inbox.id
      })
    end)
    |> Repo.transaction()
  end
end
