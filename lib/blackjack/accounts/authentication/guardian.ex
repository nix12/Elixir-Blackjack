defmodule Blackjack.Accounts.Authentication.Guardian do
  @moduledoc false
  use Guardian, otp_app: :blackjack

  alias Blackjack.Repo
  alias Blackjack.Accounts.User
  alias BlackjackWeb.Controllers.AuthenticationController

  @impl true
  def subject_for_token(%{id: id}, _claims) do
    # You can use any value for the subject of your token but
    # it should be useful in retrieving the resource later, see
    # how it being used on `resource_from_claims/1` function.
    # A unique `id` is a good subject, a non-unique id address
    # is a poor subject.
    {:ok, id}
  end

  def subject_for_token(_, _) do
    {:error, :reason_for_error}
  end

  @impl true
  def resource_from_claims(%{"sub" => id}) do
    resource = Repo.get(User, id)

    {:ok, resource}
  end

  def resource_for_claims(_claims) do
    {:error, :reason_for_error}
  end

  @impl true
  def after_sign_in(conn, resource, token, claims, options) do
    AuthenticationController.after_sign_in(conn, resource, token, claims, options)
  end

  @impl true
  def before_sign_out(conn, location, options) do
    AuthenticationController.before_sign_out(conn, location, options)
  end
end
