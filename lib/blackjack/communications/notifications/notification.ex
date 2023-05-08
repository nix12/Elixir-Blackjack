defmodule Blackjack.Communications.Notifications.Notification do
  @moduledoc """
    Notification model.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Blackjack.Accounts.User

  @derive {Jason.Encoder, only: [:body, :from, :read, :inserted_at]}

  schema "notifications" do
    field(:body, :string)
    field(:read, :boolean, default: false)
    field(:from, :string, default: "System")

    belongs_to(:recipient_inbox, Inbox, foreign_key: :recipient_inbox_id)

    timestamps()
  end

  def changeset(notification, params \\ %{}) do
    notification
    |> cast(params, [:body, :from, :recipient_inbox_id])
    |> validate_required([:body, :from])
    |> foreign_key_constraint(:recipient_inbox_id)
  end
end
