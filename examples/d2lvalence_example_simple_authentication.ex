defmodule D2lvalenceElixir.Examples.SimpleAuthentication do
  alias D2lvalenceElixir.Auth.D2LAppContext
  alias D2lvalenceElixir.Auth.D2LUserContext
  alias D2lvalenceElixir.Auth.D2LUserContextSimple
  alias D2lvalenceElixir.Auth

  def get_url_to_authenticate(app_id, app_key) do
    # You recieve the app_id and the app_key and then use the host
    # of your Brightspace instance, the callback and True for SSL (https).
    # You send the result URL to the user so he can authenticate and then
    # you recieve the user_key and user_id in the callback url.
    Auth.fashion_app_context(app_id: app_id, app_key: app_key)
    |> D2LAppContext.create_url_for_authentication(
      "brightspace.myuniversity.edu.co",
      "http://localhost:8080/token",
      true
    )
  end

  def auth_token_handler(result_url, app_id, app_key) do
    # You take the full result url (including https://yourfancyapp:8080/callback) requested after login and then generates the
    # user_context than helps your application with all the authenticated requests to de Brightspace API
    {:ok, full_user_context = %D2LUserContext{}} =
      Auth.fashion_app_context(app_id: app_id, app_key: app_key)
      |> D2LAppContext.create_user_context(
        result_uri: result_url,
        host: "brightspace.myuniversity.edu.co",
        encrypt_requests: true
      )

    # {full_user_context, simple_user_context}. I recommend to store the simple_user_context on the session
    # for security purposes (You must NOT share the app_id and app_key with the user)
    {full_user_context, full_user_context |> D2LUserContext.get_simple_user_context()}
  end

  def get_full_user_context(%D2LUserContextSimple{} = simple_user_context, app_id, app_key) do
    # If you only stores the D2LUserContextSimple, you have to generate the full_user_context to
    # make authenticated requests to the Brightspace API
    {:ok, %D2LUserContext{} = full_user_context} =
      Auth.fashion_app_context(app_id: app_id, app_key: app_key)
      |> D2LUserContext.get_full_user_context(simple_user_context)

    full_user_context
  end
end
