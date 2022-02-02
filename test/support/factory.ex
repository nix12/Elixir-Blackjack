defmodule Blackjack.Factory do
  use ExMachina.Ecto, repo: Blackjack.Repo

  alias Blackjack.Accounts.User

  def custom_user_factory(attrs) do
    user = %User{
      username: "username",
      password_hash: "password"
    }

    user
    |> Map.merge(attrs)
  end

  # def user_factory do
  #   %User{
  #     username: "username",
  #     password_hash: "password"
  #     # email: sequence(:email, &"email-#{&1}@example.com"),
  #     # role: sequence(:role, ["admin", "user", "other"]),
  #   }
  # end

  # def article_factory do
  #   title = sequence(:title, &"Use ExMachina! (Part #{&1})")
  #   # derived attribute
  #   slug = MyApp.Article.title_to_slug(title)
  #   %MyApp.Article{
  #     title: title,
  #     slug: slug,
  #     # associations are inserted when you call `insert`
  #     author: build(:user),
  #   }
  # end

  # # derived factory
  # def featured_article_factory do
  #   struct!(
  #     article_factory(),
  #     %{
  #       featured: true,
  #     }
  #   )
  # end

  # def comment_factory do
  #   %MyApp.Comment{
  #     text: "It's great!",
  #     article: build(:article),
  #   }
  # end

  def set_password(user, password) do
    hashed_password = Bcrypt.hash_pwd_salt(password)
    %{user | password_hash: hashed_password}
  end
end
