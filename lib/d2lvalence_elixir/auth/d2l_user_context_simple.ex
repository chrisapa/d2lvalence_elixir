defmodule D2lvalenceElixir.Auth.D2LUserContextSimple do
  @moduledoc """
  Simple User Context to use for security issues. You can store this struct in Phoenix session without sending the app_key and app_id to the user.
  """
  @enforce_keys [
    :scheme,
    :host,
    :user_id,
    :user_key,
    :encrypt_requests,
    :server_skew,
    :anonymous
  ]

  defstruct [
    :scheme,
    :host,
    :user_id,
    :user_key,
    :encrypt_requests,
    :server_skew,
    :anonymous
  ]
end
