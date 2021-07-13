defmodule D2lvalenceElixir.Auth.D2LAppContext do
  @moduledoc """
  Generic base module for a Valence Learning Framework API client application.
  """

  @enforce_keys [
    :app_id,
    :app_key
  ]

  defstruct [:app_id, :app_key]

  # route for requesting a user token
  @auth_api "/d2l/auth/api/token"

  # Constants for use by inheriting D2LAppContext classes, used to help keep
  # track of of the query parameter names send back by the back-end in the
  # authenticated redirect url
  @callback_url "x_target"
  @callback_user_id "x_a"
  @callback_user_key "x_b"

  # Constants for use by inheriting D2LAppContext classes, used to help keep
  # track of the query parameter names used in Valence API URLs
  @scheme_u "http"
  @scheme_s "https"
  @app_id "x_a"
  @app_sig "x_b"
  @request_type "type"

  # the valid user-context connection types understood by the back-end
  @valid_types ["mobile"]

  @spec new(String.t(), String.t()) :: %D2lvalenceElixir.Auth.D2LAppContext{
          app_id: String.t(),
          app_key: String.t()
        }
  @doc """
  Creates the struct with the context information
  """
  def new(app_id, app_key) do
    %D2lvalenceElixir.Auth.D2LAppContext{
      app_id: app_id,
      app_key: app_key
    }
  end

  @doc """
  Build a URL that the user's browser can employ to complete the user authentication process with the back-end LMS.

  :param host:
    Host/port string for the back-end LMS service (i.e. `lms.someUni.edu:443`).
    To this parameter, this function adds the appropriate API route and parameters for a user-authentication request.
  :param client_app_url:
    Client application URL that the back-end service should redirect the user back to after user-authentication.
  :param connect_type:
    Provide a type string value of `mobile` to signal to the back-end service that the user-context will connect from a mobile device.
  :param encrypt_request:
    If true (default), generate an URL using a secure scheme (HTTPS); otherwise, generate an URL for an unsecure scheme (HTTP).

  ## Examples

      iex> D2lvalenceElixir.Auth.D2LAppContext.create_url_for_authentication(%D2lvalenceElixir.Auth.D2LAppContext{"app_id": "J5fm9B0Rq934mBQV9fGLWP", "app_key": "rYBPwHlBy0wPxlP-QZPedr"}, "lms.someUni.edu:443", "http://localhost:8080/token")
      "https://lms.someUni.edu/d2l/auth/api/x_a=J5fm9B0Rq934mBQV9fGLWP&x_b=-4KVKL-uNYeXopvBXFdM0SHZgyiQCVWu0oDmF5JkL48&x_target=http%3A%2F%2Flocalhost%3A8080%2Ftoken"

  """
  def create_url_for_authentication(
        app_context = %D2lvalenceElixir.Auth.D2LAppContext{},
        host,
        client_app_url,
        connect_type \\ nil,
        encrypt_request \\ true
      ) do
    sig = D2lvalenceElixir.Auth.D2LSigner.get_hash(app_context.app_key, client_app_url)

    query =
      %{
        @app_id => app_context.app_id,
        @app_sig => sig,
        @callback_url => client_app_url
      }
      |> then(fn query ->
        cond do
          connect_type != nil and connect_type in @valid_types ->
            query
            |> Map.put(@request_type, connect_type)

          true ->
            query
        end
      end)
      |> URI.encode_query()

    scheme =
      case encrypt_request do
        true ->
          @scheme_s

        false ->
          @scheme_u
      end

    %URI{scheme: scheme, authority: host, path: @auth_api, query: query}
    |> URI.to_string()
  end

  def create_anonymous_user_context(
        %D2lvalenceElixir.Auth.D2LAppContext{} = app_context,
        host,
        options \\ []
      ) do
    defaults = [
      encrypt_requests: false
    ]

    options = Keyword.merge(defaults, options) |> Enum.into(%{})

    %{encrypt_requests: encrypt_requests} = options

    case host do
      "" ->
        {:error, "host must have a value when building a new context."}

      _ ->
        pd = %{
          "host" => host,
          "encrypt_requests" => encrypt_requests,
          "user_id" => "",
          "user_key" => "",
          "server_skew" => 0
        }

        app_context
        |> create_user_context(d2l_user_context_props_dict: pd)
    end
  end

  @spec create_user_context(
          %D2lvalenceElixir.Auth.D2LAppContext{},
          %{
            result_uri: String.t(),
            host: String.t(),
            encrypt_requests: true | false,
            d2l_user_context_props_dict: %{}
          }
          | []
        ) ::
          {:error, String.t()}
          | {:ok,
             %D2lvalenceElixir.Auth.D2LUserContext{
               anonymous: false | true,
               app_id: String.t(),
               app_key: String.t(),
               encrypt_requests: true | false,
               host: String.t(),
               scheme: String.t(),
               server_skew: String.t(),
               user_id: String.t(),
               user_key: String.t()
             }}
  @doc """
  Build a new authentication LMS-user context for a Valence Learning
  Framework API client application.

  :param result_uri:
      Entire result URI, including quoted parameters, that the back-end
      service redirected the user to after user-authentication.
  :param host:
      Host/port string for the back-end service
      (i.e. `lms.someUni.edu:443`).
  :param encrypt_requests:
      If true, use HTTPS for requests made through the resulting built
      user context; if false (the default), use HTTP.
  :param d2l_user_context_props_dict:
      If the client application already has access to the properties
      dictionary saved from a previous user context, it can provide it
      with this property. If this paramter is not `None`, this builder
      function ignores the `result_uri` parameter as not
      needed.
  """
  def create_user_context(app_context = %D2lvalenceElixir.Auth.D2LAppContext{}, options \\ []) do
    defaults = [
      result_uri: "",
      host: "",
      encrypt_requests: false,
      d2l_user_context_props_dict: %{}
    ]

    options = Keyword.merge(defaults, options) |> Enum.into(%{})

    %{
      result_uri: result_uri,
      host: host,
      encrypt_requests: encrypt_requests,
      d2l_user_context_props_dict: d2l_user_context_props_dict
    } = options

    case d2l_user_context_props_dict do
      %{} ->
        cond do
          "" in [result_uri, host] ->
            {:error, "result_uri and host must have values when building new contexts."}

          true ->
            %{query: query} = result_uri |> URI.parse()
            parsed_query = query |> URI.query_decoder() |> Map.new()

            uKey = parsed_query[@callback_user_key]
            uID = parsed_query[@callback_user_id]

            cond do
              "" in [uID, uKey] ->
                {:error, "user_id and callback_user_key not found on result_uri"}

              true ->
                D2lvalenceElixir.Auth.D2LUserContext.new(
                  host: host,
                  user_id: uID,
                  user_key: uKey,
                  app_id: app_context.app_id,
                  app_key: app_context.app_key,
                  encrypt_requests: encrypt_requests
                )
            end
        end

      t ->
        D2lvalenceElixir.Auth.D2LUserContext.new(
          host: t["host"],
          user_id: t["user_id"],
          user_key: t["user_key"],
          app_id: app_context.app_id,
          app_key: app_context.app_key,
          encrypt_requests: t["encrypt_requests"],
          server_skew: t["server_skew"]
        )
    end
  end
end
