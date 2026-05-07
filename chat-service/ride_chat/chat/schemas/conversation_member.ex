defmodule RideChat.Chat.ConversationMember do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "conversation_members" do
    field :user_id, :string
    belongs_to :conversation, RideChat.Chat.Conversation

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(member, attrs) do
    member
    |> cast(attrs, [:user_id, :conversation_id])
    |> validate_required([:user_id, :conversation_id])
    |> unique_constraint([:user_id, :conversation_id])
  end
end