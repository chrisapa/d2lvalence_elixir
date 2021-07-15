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
