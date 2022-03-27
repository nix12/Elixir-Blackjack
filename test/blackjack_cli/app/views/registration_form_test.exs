defmodule BlackjackCli.Views.RegistrationFormTest do
  @doctest BlackjackCli.Views.Registration.RegistrationForm
  use Blackjack.RepoCase, async: true

  alias BlackjackCli.Views.Registration.RegistrationForm

  setup do
    BlackjackCli.Views.Registration.RegistrationForm.start_link(:ok)
    %{registry: Registry.App}
  end

  describe "Registration form" do
    test "retrieving :tab_count field from form" do
      state = %{tab_count: 0, username: "", password: "", errors: ""}

      {:reply, response, new_state} =
        RegistrationForm.handle_call({:get_field, :tab_count}, nil, state)

      assert state == new_state
      assert response == 0
    end

    test "retrieve all fields from form" do
      state = %{tab_count: 0, username: "", password: "", errors: ""}
      {:reply, response, new_state} = RegistrationForm.handle_call({:get_fields}, nil, state)

      assert state == new_state
      assert response == state
    end

    test "update :username form field" do
      state = %{tab_count: 0, username: "", password: "", errors: ""}

      {:reply, response, new_state} =
        RegistrationForm.handle_call({:update_field, :username, "username"}, nil, state)

      assert %{tab_count: 0, username: "username", password: "", errors: ""} == new_state
      assert response.username == "username"
    end

    test "update :tab_count form field" do
      state = %{tab_count: 0, username: "", password: "", errors: ""}

      {:reply, response, new_state} =
        RegistrationForm.handle_call({:update_field, :tab_count, 1}, nil, state)

      assert %{tab_count: 1, username: "", password: "", errors: ""} == new_state
      assert response.tab_count == 1
    end
  end
end
