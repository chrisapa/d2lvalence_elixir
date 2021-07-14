defmodule D2lvalenceElixir.Utils.Service do
  @moduledoc """
  Provides a suite of convenience functions for making D2L Valence calls.
  """

  @methods %{:get => "GET"}

  # internal utility functions

  defp fetch_content(headers, body, serializers) do
    content_type = headers |> Map.get("Content-Type", "") |> String.split(";") |> List.first()

    case Map.get(serializers, content_type) do
      nil ->
        body

      serializer ->
        serializer.decode!(body)
    end
  end

  defp proccess_body(status, headers, serializers, body) when is_binary(body) do
    resp = fetch_content(headers |> Map.new(), body, serializers)

    case status do
      200 ->
        {:ok, resp}

      401 ->
        {:invalid_sig, resp}

      403 ->
        # Might also be timestamp issues here?
        {:no_permission, resp}

      _ ->
        {:unknown, resp}
    end
  end

  defp proccess_body(status, hearders, serializers, ref) when is_reference(ref) do
    case :hackney.body(ref) do
      {:ok, body} -> proccess_body(status, hearders, serializers, body)
      {:error, reason} -> {:error, reason}
    end
  end

  defp encode_request_body("", _, _), do: []
  defp encode_request_body([], _, _), do: []
  defp encode_request_body(body, "application/x-www-form-urlencoded", _), do: URI.encode(body)
  defp encode_request_body(body, _, nil), do: body
  defp encode_request_body(body, _, serializer), do: serializer.encode!(body)

  defp create_request(
         method,
         route,
         user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
         mime_type,
         serializer,
         headers \\ [],
         body \\ []
       ) do
    parameters = encode_request_body(body, mime_type, serializer)

    url =
      D2lvalenceElixir.Auth.D2LUserContext.decorate_url_with_authentication(user_context, route,
        method: Map.get(@methods, method)
      )

    :hackney.request(
      method,
      url,
      headers,
      parameters,
      follow_redirect: true,
      max_redirect: 5,
      force_redirect: true
    )
  end

  defp do_request(
         method,
         route,
         user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
         mime_type,
         serializers,
         options \\ []
       ) do
    defaults = [
      headers: [],
      body: []
    ]

    %{headers: headers, body: body} = Keyword.merge(defaults, options) |> Enum.into(%{})

    case create_request(
           method,
           route,
           user_context,
           mime_type,
           Map.get(serializers, mime_type),
           headers,
           body
         ) do
      {:ok, ref} when is_reference(ref) ->
        {:ok, ref}

      {:ok, status, headers, ref} when is_reference(ref) ->
        proccess_body(status, headers, serializers, ref)

      {:ok, status, headers, body} when is_binary(body) ->
        proccess_body(status, headers, serializers, body)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get(
         route,
         user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
         serializers,
         body \\ []
       ) do
    case user_context.anonymous do
      true ->
        {:error, "User context cannot be anonymous"}

      false ->
        do_request(
          :get,
          route,
          user_context,
          "application/x-www-form-urlencoded",
          serializers,
          headers: [],
          body: body
        )
    end
  end

  defp delete(
         route,
         user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
         serializers,
         body \\ []
       ) do
    case user_context.anonymous do
      true ->
        {:error, "User context cannot be anonymous"}

      false ->
        do_request(
          :delete,
          route,
          user_context,
          "application/x-www-form-urlencoded",
          serializers,
          headers: [],
          body: body
        )
    end
  end

  defp post(
         route,
         user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
         serializers,
         body \\ []
       ) do
    case user_context.anonymous do
      true ->
        {:error, "User context cannot be anonymous"}

      false ->
        do_request(
          :post,
          route,
          user_context,
          "application/json",
          serializers,
          headers: %{"Content-Type" => "application/json"},
          body: body
        )
    end
  end

  defp put(
         route,
         user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
         serializers,
         body \\ []
       ) do
    case user_context.anonymous do
      true ->
        {:error, "User context cannot be anonymous"}

      false ->
        do_request(
          :put,
          route,
          user_context,
          "application/x-www-form-urlencoded",
          serializers,
          headers: [],
          body: body
        )
    end
  end

  defp get_anon(
         route,
         user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
         serializers,
         body \\ []
       ) do
    do_request(
      :get,
      route,
      user_context,
      "application/x-www-form-urlencoded",
      serializers,
      headers: [],
      body: body
    )
  end

  defp post_anon(
         route,
         user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
         serializers,
         body \\ []
       ) do
    do_request(
      :post,
      route,
      user_context,
      "application/json",
      serializers,
      headers: %{"Content-Type" => "application/json"},
      body: body
    )
  end

  ## TODO - For future releases
  defp simple_upload(
         route,
         user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
         f,
         serializers,
         body \\ []
       ),
       do: {:error, "Unimplemented function"}

  # API properties functions

  @spec get_versions_for_product_component(%D2lvalenceElixir.Auth.D2LAppContext{}, String.t(), %{
          version: String.t() | nil,
          serializers: map() | %{},
          body: map() | %{}
        }) :: {:error, String.t()} | {:ok, list()} | {:ok, binary()}
  @doc """
  Gets the version of a product component especified in product component.

  ## Returns
  `{:error, cause}` when an error is caused.

  `{:ok, list}` If application/json serializer available returns a list with the product versions available

  ## Options
  version: version of the component to verify. If not specified, will get the version of the component.
  serializers: Map of availaber serializers. application/json recommended.
  body: Options to pass to the body of the request.
  """
  def get_versions_for_product_component(
        user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
        product_component,
        options \\ []
      ) do
    defaults = [
      version: nil,
      serializers: %{},
      body: []
    ]

    %{serializers: serializers, body: body, version: version} =
      Keyword.merge(defaults, options) |> Enum.into(%{})

    case version do
      nil -> "/d2l/api/#{product_component}/versions/"
      version -> "/d2l/api/#{product_component}/versions/#{version}"
    end
    |> get_anon(user_context, serializers, body)
  end

  @spec get_all_versions(%D2lvalenceElixir.Auth.D2LUserContext{}, %{
          serializers: map() | %{},
          body: map() | []
        }) :: {:error, String.t()} | {:ok, list(map())} | {:ok, binary()}
  @doc """
  Gets the versions of all components.

  ## Returns
  `{:error, cause}` when an error is caused.

  `{:ok, list(map())}` If application/json serializer available returns a list of maps with the products available and its versions:

  `[%{"LatestVersion" => "1.1",
  "ProductCode" => "bas",
  "SupportedVersions" => ["1.0", "1.1"]}]`

  ## Options
  serializers: Map of availaber serializers. application/json recommended.
  body: Options to pass to the body of the request.
  """
  def get_all_versions(
        user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
        options \\ []
      ) do
    defaults = [
      serializers: %{},
      body: []
    ]

    %{serializers: serializers, body: body} = Keyword.merge(defaults, options) |> Enum.into(%{})

    "/d2l/api/versions/"
    |> get_anon(user_context, serializers, body)
  end

  @spec check_versions(
          %D2lvalenceElixir.Auth.D2LUserContext{},
          list(%D2lvalenceElixir.Data.SupportedVersionRequest{}),
          %{serializers: map() | %{}, body: map() | []}
        ) ::
          {:error, String.t()} | {:ok, list(map())} | {:ok, binary()}
  @doc """
  Check if the Version of products requested are supported by the D2L instance
  """
  def check_versions(
        user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
        supported_version_request_list,
        options \\ []
      ) do
    defaults = [
      serializers: %{},
      body: []
    ]

    %{serializers: serializers, body: body} = Keyword.merge(defaults, options) |> Enum.into(%{})

    supported_version_request_list
    |> Enum.any?(fn
      %D2lvalenceElixir.Data.SupportedVersionRequest{} ->
        false

      _ ->
        true
    end)
    |> case do
      true ->
        {:error, "All supported version must be %D2lvalenceElixir.Data.SupportedVersionRequest{}"}

      false ->
        "/d2l/api/versions/check"
        |> post_anon(user_context, serializers, body)
    end
  end

  @spec get_whoami(
          %D2lvalenceElixir.Auth.D2LUserContext{},
          %{serializers: %{}, ver: String.t()}
        ) :: {:error, String.t()} | {:ok, any}
  @doc """
  Calls the Whoami service of Brightspace.

  ## Returns
  `{:error, cause}` when an error is caused.

  `{:ok, body_parsed}` The body_parsed depends on the availabe serializers.

  ## Options
  version: version of the component to verify. If not specified, will get the version of the component.
  serializers: Map of availaber serializers. application/json recommended.
  body: Options to pass to the body of the request.
  """
  def get_whoami(
        user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
        options \\ []
      ) do
    defaults = [
      serializers: %{},
      ver: "1.0"
    ]

    options = Keyword.merge(defaults, options) |> Enum.into(%{})

    %{serializers: serializers, ver: ver} = options

    "/d2l/api/lp/#{ver}/users/whoami"
    |> get(user_context, serializers)
  end
end
