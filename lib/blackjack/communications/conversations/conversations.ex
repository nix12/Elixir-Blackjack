defmodule Blackjack.Communications.Conversations.Conversations do
  alias Blackjack.Repo
  alias Blackjack.Communications.Conversations.Conversation

  def create_or_continue_conversation(current_user, requested_user) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:get_current_user_conversation, fn _repo, _changes ->
      {:ok,
       Repo.get_by(Conversation, user_id: current_user.id, recipient_id: requested_user.id) ||
         %Conversation{}}
    end)
    |> Ecto.Multi.insert_or_update(:current_user_conversation, fn %{
                                                                    get_current_user_conversation:
                                                                      current_user_conversation
                                                                  } ->
      Ecto.Changeset.change(current_user_conversation, %{
        user_id: current_user.id,
        recipient_id: requested_user.id
      })
    end)
    |> Ecto.Multi.run(:get_recipient_conversation, fn _repo, _changes ->
      {:ok,
       Repo.get_by(Conversation, user_id: requested_user.id, recipient_id: current_user.id) ||
         %Conversation{}}
    end)
    |> Ecto.Multi.insert_or_update(:recipient_conversation, fn %{
                                                                 get_recipient_conversation:
                                                                   recipient_conversation
                                                               } ->
      Ecto.Changeset.change(recipient_conversation, %{
        user_id: requested_user.id,
        recipient_id: current_user.id
      })
    end)
    |> Repo.transaction()
  end
end
