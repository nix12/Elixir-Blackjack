defmodule RegisterUserTest do
  use Blackjack.RepoCase, async: false
  use Plug.Test

  describe "POST /register" do
    test "success!" do
      user_params = %{
        user: %{
          email: Faker.Internet.email(),
          username: Faker.Internet.user_name(),
          password_hash: "password"
        }
      }

      %HTTPoison.Response{body: body, status_code: status} = register_path(user_params)

      assert status == 201

      assert %{
               "user" => %{
                 "email" => _,
                 "username" => _,
                 "password_hash" => _,
                 "inserted_at" => _,
                 "updated_at" => _
               }
             } = body |> Jason.decode!()
    end

    test "failure!" do
      user = build(:user) |> set_password("password") |> insert()

      user_params = %{
        user: %{
          email: user.email,
          username: user.username,
          password_hash: "password"
        }
      }

      %HTTPoison.Response{body: body, status_code: status} = register_path(user_params)

      assert status == 422
      assert %{"errors" => "username has already been taken."} = body |> Jason.decode!()
    end
  end
end
