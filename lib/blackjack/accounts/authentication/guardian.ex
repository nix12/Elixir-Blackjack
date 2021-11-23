defmodule Blackjack.Accounts.Authentication.Guardian do
  use Guardian, otp_app: :blackjack
  require Logger
  alias Blackjack.Accounts

  def subject_for_token(%{username: username}, _claims) do
    # You can use any value for the subject of your token but
    # it should be useful in retrieving the resource later, see
    # how it being used on `resource_from_claims/1` function.
    # A unique `id` is a good subject, a non-unique email address
    # is a poor subject.
    {:ok, username}
  end

  def subject_for_token(_, _) do
    {:error, :reason_for_error}
  end

  def resource_from_claims(%{"sub" => username}) do
    resource = Accounts.get_user(username)
    Logger.info("CLAIMS: #{inspect(resource)}")
    {:ok, resource}
  end

  def resource_for_claims(_claims) do
    {:error, :reason_for_error}
  end
end
