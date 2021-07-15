# D2lvalenceElixir - Desire2Learn Client Library for Elixir

Elixir implementation of d2lvalence to connecto to the Desire2Learn's Valence API.

Based on [Desire2Learn Client Library for Python](https://github.com/Brightspace/valence-sdk-python)

Works with the [Brightspace Api Rest](https://docs.valence.desire2learn.com/reference.html)

**Auth:** The D2lvalenceElixir.Auth module provides assistance for the authentication needed to invoke Valence APIs. You use the module's functiones to create a %D2lvalenceElixir.Auth.D2LUserContext{} struct that you can then employ as an authentication helper.

**Service:** The D2lvalenceElixir.Utils.Service module provides many functions to call the Brightspace API Rest according to their documentation.

## Installation

The package can be installed by adding `d2lvalence_elixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:d2lvalence_elixir, "~> 0.1.0"}
  ]
end
```

## Use

### Authentication

```elixir
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
      "bloqueneon.uniandes.edu.co",
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
        host: "bloqueneon.uniandes.edu.co",
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
``

### Simple calls

```elixir
defmodule D2lvalenceElixir.Examples.SimpleApiCalls do
  alias D2lvalenceElixir.Auth.D2LUserContext
  alias D2lvalenceElixir.Utils.Service
  alias D2lvalenceElixir.Data.WhoAmIUser

  def serializers do
    # To encode and decode the requests, you could need some serializers.
    # This function creates the map with the serializers you need.
    # You need an application/json at least.
    %{}
    |> Map.put("application/json", Jason)
  end

  def whoami_api_call(%D2LUserContext{} = user_context) do
    # With the user_context (full_user_context, not simple) you call the whoami
    # You have to send the serializers, at least an application/json to decode the result
    # I use this version because it works on my university
    # The WhoAmI call shows who is the authenticated with the user_context
    {:ok, user = %WhoAmIUser{}} =
      user_context
      |> Service.get_whoami(serializers: serializers(), ver: "1.23")

    user
  end

  def get_all_versions_api_call(%D2LUserContext{} = user_context) do
    # With the user context, shows the information of all the products of the Brightspace instance
    {:ok, products_information} =
      user_context
      |> Service.get_all_versions(serializers: serializers(), ver: "1.23")

    products_information
  end
end
```