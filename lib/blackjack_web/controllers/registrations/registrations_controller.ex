defmodule BlackjackWeb.Controllers.RegistrationsController do
  def register do
    username =
      IO.gets("What username would you like to register?\n")
      |> to_string()
      |> String.trim()

    password = Mix.Tasks.Hex.password_get("Enter password: ") |> String.replace_trailing("\n", "")

    password_confirmation =
      Mix.Tasks.Hex.password_get("Enter password confirmation: ")
      |> String.replace_trailing("\n", "")

    if password_confirmation == password do
      credentials = %{user: %{username: "#{username}", password_hash: "#{password}"}}

      send_credentials(credentials)
    else
      register()
    end
  end

  defp send_credentials(credentials) do
    {:ok, {response, _, _}} =
      :httpc.request(
        :post,
        {'http://localhost:4000/user/register', [], 'application/json',
         Jason.encode!(credentials)},
        [],
        []
      )

    response
  end
end
