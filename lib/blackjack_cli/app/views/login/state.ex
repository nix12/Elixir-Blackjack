defmodule BlackjackCli.Views.Login.State do
  @moduledoc """
    Updates the terminal view of the login view.
  """
  import Ratatouille.Constants, only: [key: 1]

  alias BlackjackCli.Views.Login.LoginForm

  @space_bar key(:space)
  @tab key(:tab)
  @enter key(:enter)
  @up key(:arrow_up)
  @down key(:arrow_down)

  @delete_keys [
    key(:delete),
    key(:backspace),
    key(:backspace2)
  ]

  @type model() :: Map.t()
  @type event() :: Tuple.t()

  @doc """
    Takes a model and an event to evaluate and update login view.
  """
  @spec update(model(), event()) :: map()
  def update(model, msg) do
    case msg do
      {:event, %{key: @tab}} ->
        current_tab = LoginForm.get_field(:tab_count)
        LoginForm.update_field(:tab_count, current_tab + 1)
        update_user(%{model | input: ""})

      {:event, %{key: key}} when key in @delete_keys ->
        update_user(%{model | input: String.slice(model.input, 0..-2)})

      {:event, %{key: @space_bar}} ->
        update_user(%{
          model
          | input: (model.input |> to_string |> String.replace(~r/^[[:digit:]]+$/, "")) <> " "
        })

      {:event, %{ch: ch}} when ch > 0 ->
        case model.input do
          0 ->
            # Changes the input from integer to empty string to be operated on for input.
            update_user(%{model | input: "" <> <<ch::utf8>>})

          input ->
            # replace_prefix is meant to clear the string before each character input.
            update_user(%{model | input: String.replace_prefix(input, input, "") <> <<ch::utf8>>})
        end

      {:event, %{ch: ?w}} ->
        %{model | input: max(model.input - 1, 0)}

      {:event, %{key: @up}} ->
        %{model | input: max(model.input - 1, 0)}

      {:event, %{ch: ?s}} ->
        %{model | input: min(model.input + 1, length(menu()) - 1)}

      {:event, %{key: @down}} ->
        %{model | input: min(model.input + 1, length(menu()) - 1)}

      {:event, %{key: @enter}} ->
        case model.menu == true do
          false ->
            login(model) |> tap(&IO.inspect/1)

          _ ->
            if match_menu(model) == :login do
              login(model)
            else
              %{model | screen: match_menu(model), input: 0}
            end
        end

      _ ->
        update_user(model)
    end
  end

  defp menu do
    [:start, :login]
  end

  defp match_menu(model) do
    menu()
    |> Enum.at(model.input)
  end

  def start_login do
    LoginForm.start_link(:ok)
  end

  defp update_user(%{input: input, screen: screen} = model) do
    case LoginForm.get_field(:tab_count) do
      0 ->
        LoginForm.update_field(:username, input)
        %{model | input: input, screen: screen}

      1 ->
        LoginForm.update_field(:password, input)
        %{model | input: input, screen: screen}

      2 ->
        case model.menu do
          true ->
            %{model | menu: false, input: ""}

          _ ->
            %{model | menu: true, input: 0}
        end

      _ ->
        LoginForm.update_field(:tab_count, 0)
        model
    end
  end

  defp login_request(user_params) do
    {:ok, {{_protocol, code, _message}, _meta, resource}} =
      :httpc.request(
        :post,
        {'http://localhost:#{Application.get_env(:blackjack, :port)}/login', [],
         'application/json', Jason.encode!(user_params)},
        [],
        []
      )

    {code, Jason.decode!(resource)}
  end

  defp login_verify(model, code, resource) do
    case code do
      code when code >= 200 and code < 300 ->
        LoginForm.close_form()

        %{
          model
          | screen: :menu,
            token: resource["token"],
            input: 0,
            user: %{username: resource["user"]["username"]},
            menu: true
        }

      _ ->
        IO.inspect("LOGIN VERIFY ERROR")
        LoginForm.update_field(:errors, resource["errors"])
        %{model | screen: :login, token: nil}
    end
  end

  defp login(model) do
    user_params = %{
      user: %{
        username: LoginForm.get_field(:username),
        password_hash: LoginForm.get_field(:password)
      }
    }

    with :ok <- validate_username(user_params.user.username),
         :ok <- validate_password(user_params.user.password_hash) do
      {code, resource} = login_request(user_params)

      login_verify(model, code, resource)
    else
      {:error, message} ->
        LoginForm.update_field(:errors, message)
        update_user(%{model | input: model.input, screen: :login})
    end
  end

  defp validate_username(username) do
    case Blackjack.blank?(username) do
      true ->
        {:error, "username cannot be blank."}

      _ ->
        :ok
    end
  end

  defp validate_password(password) do
    case Blackjack.blank?(password) do
      true ->
        {:error, "password cannot be blank."}

      _ ->
        :ok
    end
  end
end
