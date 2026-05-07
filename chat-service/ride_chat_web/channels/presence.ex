defmodule RideChatWeb.Presence do
  # ใช้ OTP และ PubSub เพื่อกระจายสถานะ Online ไปยังทุก Server ใน Cluster
  use Phoenix.Presence, otp_app: :ride_chat,
                        pubsub_server: RideChat.PubSub
end
