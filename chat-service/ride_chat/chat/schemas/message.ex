defmodule RideChat.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "messages" do
    field :content, :string
    field :sender_id, :string # UUID of user
    field :type, :string, default: "text" # text, image, location, system
    field :payload, :map, default: %{} # {url: "...", width: 100}

    belongs_to :conversation, RideChat.Chat.Conversation

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :sender_id, :type, :payload, :conversation_id])
    |> validate_required([:content, :sender_id, :conversation_id])
  end
end