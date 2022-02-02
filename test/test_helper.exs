# Mox.defmock(UserBehaviourMock, for: UserBehaviour)
# Application.put_env(:blackjack, :user, UserBehaviourMock)

ExUnit.start()
{:ok, _} = Application.ensure_all_started(:ex_machina)
# {:ok, _} = Application.ensure_all_started(:mox)
