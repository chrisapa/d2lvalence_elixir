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
  defp encode_request_body([], _, _), do: ""
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

  defp get(
         route,
         user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
         serializers,
         options \\ []
       ) do
    case user_context.anonymous do
      true ->
        {:error, "User context cannot be anonymous"}

      false ->
        case create_request(
               :get,
               route,
               user_context,
               "application/x-www-form-urlencoded",
               Map.get(serializers, "application/x-www-form-urlencoded"),
               [],
               options
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
  end

  @spec get_whoami(
          %D2lvalenceElixir.Auth.D2LUserContext{},
          %{serializers: %{}, ver: String.t()}
        ) :: {:error, String.t()} | {:ok, any}
  @doc """
  Calls the Whoami service of Brightspace.
  Returns {:error, cause} when an error is caused.
  Returns {:ok, body_parsed}. The body_parsed depends on the availabe serializers.
  When calling, send an application/json serializer inside serializers.
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
