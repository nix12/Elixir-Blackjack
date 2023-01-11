defmodule Blackjack.Communications.Messages.Messages do
  alias Blackjack.Repo
  alias Blackjack.Accounts.{User, Inbox}
  alias Blackjack.Communications.Messages.Message

  def create_message(current_user, conversation, message) do
    changeset =
      Message.changeset(
        %Message{},
        message
        |> Map.put(:user_id, current_user.id)
        |> Map.put(:conversation_id, conversation.id)
      )
      |> IO.inspect()

    case changeset
         |> Repo.insert() do
      {:ok, _message} = new_message ->
        new_message

      {:error, _changeset} = error ->
        error
    end
  end
end
