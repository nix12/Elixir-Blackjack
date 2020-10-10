defmodule Blackjack.Authentication.Guardian do
  use Guardian, otp_app: :blackjack

  alias Blackjack.Repo
  alias Blackjack.Web.Models.User

  def get_resource_by_id(id) do
    case Repo.get_by(User, id: id) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end

  def subject_for_token(resource, _claims) do
    # You can use any value for the subject of your token but
    # it should be useful in retrieving the resource later, see
    # how it being used on `resource_from_claims/1` function.
    # A unique `id` is a good subject, a non-unique email address
    # is a poor subject.

    sub = to_string(resource.id)
    {:ok, sub}
  end

  def subject_for_token(_, _) do
    {:error, :token_not_found}
  end

  def resource_from_claims(claims) do
    resource = get_resource_by_id(claims.id)
    {:ok, resource}
  end

  def resource_from_claims(_claims) do
    {:error, :claims_not_found}
  end
end
