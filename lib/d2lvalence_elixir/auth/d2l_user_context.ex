defmodule D2lvalenceElixir.Auth.D2LUserContext do
  @enforce_keys [
    :scheme,
    :host,
    :user_id,
    :user_key,
    :app_id,
    :app_key,
    :encrypt_requests,
    :server_skew,
    :anonymous
  ]

  defstruct [
    :scheme,
    :host,
    :user_id,
    :user_key,
    :app_id,
    :app_key,
    :encrypt_requests,
    :server_skew,
    :anonymous
  ]

  # Constants for use by inheriting D2LUserContext classes, used to help keep
  # track of the query parameter names used in Valence API URLs.
  @scheme_p "http"
  @scheme_s "https"

  @app_id "x_a"
  @app_sig "x_c"
  @user_id "x_b"
  @user_sig "x_d"
  @time "x_t"

  @spec new(%{
          host: String.t(),
          user_id: String.t(),
          user_key: String.t(),
          app_id: String.t(),
          app_key: String.t(),
          encrypt_requests: true | false,
          server_skew: Integer.t()
        }) ::
          {:error, String.t()}
          | {:ok,
             %D2lvalenceElixir.Auth.D2LUserContext{
               anonymous: false | true,
               app_id: String.t(),
               app_key: String.t(),
               encrypt_requests: boolean,
               host: String.t(),
               scheme: String.t(),
               server_skew: Integer.t(),
               user_id: String.t(),
               user_key: String.t()
             }}
  @doc """
  Constructs a new authenticated calling user context.

  Clients are not intended to invoke this constructor directly; rather
  they should use the `D2LAppContext.create_user_context()` factory
  method, or the `fashion_user_context()` factory function.

  :param hostName: Host/port string for the back-end service.
  :param user_id: User ID provided by the back-end service to the
                  authenticated client application.
  :param user_key: User Key provided by the back-end service to the
                   authenticated client application.
  :param encrypt_requests: If true, use HTTPS for requests made through
                           this user context; if false (the default), use
                           HTTP.
  :param server_skew: Time skew between the service's time and the client
                      application's time, in milliseconds.
  :param signer: A signer instance that implements D2LSigner.

  :return error:: If you provide `None` for hostName, port, user_id,
                      or user_key parameters.
  """
  def new(options \\ []) do
    defaults = [
      host: "",
      user_id: "",
      user_key: "",
      app_id: "",
      app_key: "",
      encrypt_requests: false,
      server_skew: 0
    ]

    options = Keyword.merge(defaults, options) |> Enum.into(%{})

    %{
      host: host,
      user_id: user_id,
      user_key: user_key,
      app_id: app_id,
      app_key: app_key,
      encrypt_requests: encrypt_requests,
      server_skew: server_skew
    } = options

    scheme =
      case encrypt_requests do
        true -> @scheme_s
        false -> @scheme_p
      end

    cond do
      user_id == "" != (user_key == "") ->
        {:error,
         "Anonymous context must have user_id and user_key empty; or, user context must have both user_id and user_key with values."}

      "" in [host, app_id, app_key] ->
        {:error, "host, app_id, and app_key must have values."}

      true ->
        anonymous =
          case user_id do
            "" -> True
            _ -> False
          end

        {:ok,
         %D2lvalenceElixir.Auth.D2LUserContext{
           host: host,
           user_id: user_id,
           user_key: user_key,
           app_id: app_id,
           app_key: app_key,
           encrypt_requests: encrypt_requests,
           server_skew: server_skew,
           anonymous: anonymous,
           scheme: scheme
         }}
    end
  end

  defp get_time_string(%D2lvalenceElixir.Auth.D2LUserContext{} = user_context) do
    # we must pass back seconds; :os.system_time(:second) returns seconds, server_skew is in millis
    round(:os.system_time(:second) + user_context.server_skew / 1000)
    |> to_string()
  end

  defp build_tokens_for_path(
         %D2lvalenceElixir.Auth.D2LUserContext{} = context,
         path,
         options \\ []
       ) do
    defaults = [
      method: "GET"
    ]

    options = Keyword.merge(defaults, options) |> Enum.into(%{})

    %{method: method} = options

    time = get_time_string(context)

    bs_path = path |> String.downcase() |> URI.decode()

    base = "#{String.upcase(method)}&#{bs_path}&#{time}"

    app_sig = D2lvalenceElixir.Auth.D2LSigner.get_hash(context.app_key, base)

    user_sig =
      case context.anonymous do
        true ->
          ""

        false ->
          D2lvalenceElixir.Auth.D2LSigner.get_hash(context.user_key, base)
      end

    %{
      @app_id => [context.app_id],
      @app_sig => [app_sig],
      @user_id => [context.user_id],
      @user_sig => [user_sig],
      @time => [time]
    }
  end

  @spec decorate_url_with_authentication(
          %D2lvalenceElixir.Auth.D2LUserContext{},
          String.t(),
          %{method: String.t()} | []
        ) ::
          String.t()
  @doc """
  Create a properly tokenized URL for a new request through this user
  context, starting from a full URL.

  :param url: Full URL to call on the back-end service; no default value.
  param method: Method for the request (GET by default, POST, etc).

  :returns: URL you can use for an HTTP request, containing the
  time-limited authentication token parameters needed for a Valence API
  call.
  """
  def decorate_url_with_authentication(
        %D2lvalenceElixir.Auth.D2LUserContext{} = user_context,
        url,
        options \\ []
      ) do
    defaults = [
      method: "GET"
    ]

    options = Keyword.merge(defaults, options) |> Enum.into(%{})

    %{method: method} = options

    %URI{scheme: scheme_url, host: netloc_url, path: path, query: query, fragment: fragment} =
      URI.parse(url)

    scheme =
      case scheme_url do
        nil -> user_context.scheme
        scheme_url -> scheme_url
      end

    netloc =
      case netloc_url do
        nil -> user_context.host
        netloc_url -> netloc_url
      end

    query_result =
      query
      |> Map.new()
      |> Map.merge(path |> build_tokens_for_path(method: method))
      |> URI.encode_query()

    %URI{scheme: scheme, authority: netloc, path: path, query: query_result, fragment: fragment}
    |> URI.to_string()
  end

  @spec create_authenticated_url(
          %D2lvalenceElixir.Auth.D2LUserContext{},
          %{method: String.t()}
          | %{api_route: String.t()}
          | %{method: String.t(), api_route: String.t()}
          | []
        ) :: String.t()
  @doc """
  Create a properly tokenized URL for a new request through this user context.

  :param api_route: API route to invoke on the back-end service (get all
  versions route by default).
  :param method: Method for the request (GET by default, POST, etc).

  :returns: URI string you can fashion into an HTTP request, containing
  the time-limited authentication token parameters needed for a Valence
  API call.
  """
  def create_authenticated_url(
        %D2lvalenceElixir.Auth.D2LUserContext{} = user_context,
        options \\ []
      ) do
    defaults = [
      api_route: "/d2l/api/versions/",
      method: "GET"
    ]

    options = Keyword.merge(defaults, options) |> Enum.into(%{})

    %{method: method, api_route: api_route} = options

    scheme =
      case user_context.encrypt_requests do
        true -> @scheme_p
        false -> @scheme_s
      end

    netloc = user_context.host
    path = api_route

    query = path |> build_tokens_for_path(method: method) |> URI.encode_query()

    %URI{scheme: scheme, authority: netloc, path: path, query: query}
    |> URI.to_string()
  end

  # "Currently, this function does very little, and is present mostly for
  # symmetry with the other Valence client library packages."
  # This id the comment in the D2LValence python implementation, and I mantain this here.
  @spec interpret_result(
          %D2lvalenceElixir.Auth.D2LUserContext{},
          Integer.t(),
          String.t(),
          String.t() | nil
        ) ::
          :invalid_sig | :no_permission | :okay | :unknown
  @doc """
  Interpret the result made for an API call through this user context.

  :param result_code:
    The HTTP result code from the response; if a successful result
    (2xx), this method ignores the response.
  :param response:
    Response passed back by the back-end service. The precise form of
    this is implementation dependent. It could be a string, or a file
    object, or a Response object of some kind.
  :param logfile:
    Optional. A caller might want to provide a file stream for logging
    purposes; if present, this method should write logging messages to
    this file stream.

  :returns: One of the enumerated D2LAuthResult class variables.
  """
  def interpret_result(_, result_code, _, _) do
    case result_code do
      200 ->
        :okay

      401 ->
        :invalid_sig

      403 ->
        # Might also be timestamp issues here?
        :no_permission

      _ ->
        :unknown
    end
  end

  @spec set_new_skew(%D2lvalenceElixir.Auth.D2LUserContext{}, Integer.t()) ::
          %D2lvalenceElixir.Auth.D2LUserContext{}
  @doc """
  Adjust the known time skew between the local client using this
    user context, and the back-end service.
    :param newSkewMillis: New server time-skew value, in milliseconds.

  """
  def set_new_skew(%D2lvalenceElixir.Auth.D2LUserContext{} = user_context, new_skew) do
    user_context
    |> Map.update!(:server_skew, new_skew)
  end
end
