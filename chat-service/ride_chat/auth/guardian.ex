defmodule RideChat.Auth.Guardian do
  use Guardian, otp_app: :ride_chat

  def subject_for_token(user_id, _claims), do: {:ok, to_string(user_id)}
  
  def resource_from_claims(%{"sub" => id}), do: {:ok, id}
  def resource_from_claims(_), do: {:error, :reason_missing_sub}
end