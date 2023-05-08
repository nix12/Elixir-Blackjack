defmodule Blackjack.Communications.Messages.Messages do
  alias Blackjack.Repo
  alias Blackjack.Accounts.{User, Inbox}
  alias Blackjack.Communications.Messages.Message

  def create_message(message) do
    changeset = Message.changeset(%Message{}, message)

    case changeset |> IO.inspect(label: "MSG CHANGESET") |> Repo.insert() do
      {:ok, _message} = new_message ->
        new_message

      {:error, _changeset} = error ->
        error
    end
  end
end
