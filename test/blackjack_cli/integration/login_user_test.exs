defmodule LoginUserTest do
  use Blackjack.RepoCase, async: true
  use Plug.Test
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  # setup_all do
  #   Application.stop(:blackjack)
  #   :ok = Application.start(:blackjack)
  # end

  setup_all do
    HTTPoison.start()
    :ok
  end

  # setup do
  #   build(:custom_user, username: "username") |> set_password("password") |> insert()
  #   :ok
  # end

  setup do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    :ok
  end

  # setup do
  #   on_exit(fn ->
  #     Blackjack.Repo.delete_all(Blackjack.Accounts.User)
  #   end)
  # end

  describe "POST /login" do
    test "success!" do
      build(:custom_user, username: "username")
      |> set_password("password")
      |> insert()
      |> tap(&IO.inspect(&1, label: "INSERT"))

      IO.inspect(Blackjack.Repo.all(Blackjack.Accounts.User), label: "=====> TEST REPO <=====")

      user_params = %{
        user: %{
          username: "username",
          password_hash: "password"
        }
      }

      use_cassette "httpc_login_request" do
        {:ok,
         %HTTPoison.Response{
           body: body,
           headers: _headers,
           status_code: _status
         }} = Blackjack.login_path(user_params)

        assert body =~ ~r/#{Jason.encode!(user_params)}/
      end
    end
  end
end
