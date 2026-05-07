defmodule RideChat.Chat.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "conversations" do
    field :booking_id, :string  # Reference to Go Backend Booking
    field :status, :string, default: "active" # active, archived
    field :metadata, :map, default: %{}

    has_many :messages, RideChat.Chat.Message
    has_many :members, RideChat.Chat.ConversationMember

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:booking_id, :status, :metadata])
    |> validate_required([:booking_id])
    |> unique_constraint(:booking_id)
  end
end