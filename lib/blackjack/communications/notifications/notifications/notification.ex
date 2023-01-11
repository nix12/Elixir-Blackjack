defmodule Blackjack.Communications.Notifications.Notification do
  @moduledoc """
    Notification model.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:body, :read, :inserted_at]}

  schema "notifications" do
    field(:body, :string)
    field(:read, :boolean, default: false)
    field(:user_id, :binary_id)

    timestamps()
  end

  def changeset(notification, params \\ %{}) do
    notification
    |> cast(params, [:body, :user_id])
    |> validate_required([:body, :user_id])
  end
end
