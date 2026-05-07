defmodule RideChat.Repo.Migrations.CreateChatTables do
  use Ecto.Migration

  def change do
    # 1. เปิดใช้ UUID (มาตรฐาน Enterprise ห้ามใช้ ID 1,2,3)
    execute("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"", "DROP EXTENSION \"uuid-ossp\"")

    # 2. ตาราง Conversations (ห้องแชท)
    create table(:conversations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :booking_id, :string, null: false # เชื่อมกับ Go Backend
      add :status, :string, default: "active"
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:conversations, [:booking_id])

    # 3. ตาราง Members (ใครอยู่ในห้องบ้าง)
    create table(:conversation_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :conversation_id, references(:conversations, on_delete: :delete_all, type: :binary_id)
      add :user_id, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:conversation_members, [:conversation_id])
    create index(:conversation_members, [:user_id])
    # ห้าม User คนเดิม เข้าห้องเดิมซ้ำ
    create unique_index(:conversation_members, [:conversation_id, :user_id])

    # 4. ตาราง Messages (ข้อความ)
    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :conversation_id, references(:conversations, on_delete: :delete_all, type: :binary_id)
      add :sender_id, :string, null: false
      add :content, :text
      add :type, :string, default: "text" # text, image, location
      add :payload, :map, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    # Index เพื่อให้ดึงประวัติแชทไวๆ (Sort ตามเวลา)
    create index(:messages, [:conversation_id, :inserted_at])
  end
end