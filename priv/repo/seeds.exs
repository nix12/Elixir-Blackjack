alias Blackjack.Repo
alias Blackjack.Accounts.{User, Friendship}
alias Blackjack.Accounts.Inbox.{Inbox, Inboxes}
alias Blackjack.Communications.Conversations.{Conversation, Conversations}
alias Blackjack.Communications.Notifications.{Notification, Notifications}
alias Blackjack.Communications.Messages.{Message, Messages}
alias Blackjack.Accounts.Inbox.InboxesConversations

Repo.delete_all(Message)
Repo.delete_all(Conversation)
Repo.delete_all(Notification)
Repo.delete_all(InboxesConversations)
Repo.delete_all(Inbox)
Repo.delete_all(User)

for n <- 1..5 do
  User.changeset(%User{}, %{
    email: "user#{n}@email.com",
    username: "user#{n}",
    password_hash: "pass"
  })
  |> Repo.insert!()
  |> Inboxes.create_inbox()
end

user1 = Repo.get_by(User, username: "user1")
user2 = Repo.get_by(User, username: "user2")
user3 = Repo.get_by(User, username: "user3")
user4 = Repo.get_by(User, username: "user4")
user5 = Repo.get_by(User, username: "user5")

{:ok, %{current_user_conversation: conversation1}} =
  Conversations.create_or_continue_conversation(user1, user2)

Messages.create_message(%{
  body: "Hello, how are you?",
  user_id: user1.id,
  conversation_id: conversation1.id
})

Messages.create_message(%{
  body: "Very good, thank you. And how about your?",
  user_id: user2.id,
  conversation_id: conversation1.id
})

Messages.create_message(%{
  body: "I am just swell.",
  user_id: user1.id,
  conversation_id: conversation1.id
})

Messages.create_message(%{
  body: "Amet nulla eiusmod amet aliquip nostrud esse proident. Do anim amet ipsum in eiusmod enim
    occaecat deserunt. In ullamco fugiat esse duis culpa dolor. Sint velit consequat enim culpa.
    xercitation sunt nisi voluptate anim eiusmod commodo labore culpa do excepteur adipisicing
    amet excepteur id. Nulla adipisicing minim commodo ut dolore anim amet dolor veniam nisi
    proident elit consectetur laboris.
  Enim irure aute do elit ex ad proident minim tempor eiusmod amet veniam consequat. Id aliqua
  proident aliquip velit laborum occaecat ipsum non incididunt. Ullamco aliquip non enim ut ut.
  Nisi elit veniam eu in pariatur elit amet tempor minim aute in proident laborum. Amet do do
  ex consectetur deserunt ad laborum.
  Elit ad sunt ex qui irure magna. Do aliquip occaecat dolor incididunt amet excepteur. Eu
  adipisicing elit aliquip ad Lorem anim nisi. Et aliquip ad in consectetur cillum irure velit
  voluptate duis aute eu. Magna mollit ex do in dolor. Ad velit ad ut do in velit qui do tempor
  laboris esse non commodo. Mollit in officia irure deserunt est veniam.",
  user_id: user2.id,
  conversation_id: conversation1.id
})

{:ok, notification1} =
  Notifications.create_notification(%{from: "System", body: "The system has been updated."})

Notifications.send_notification(notification1)

{:ok, notification2} =
  Notifications.create_notification(%{
    from: "System",
    body: "System update for #{DateTime.now!("Etc/UTC") |> DateTime.to_string()}"
  })

Notifications.send_notification(notification2)
