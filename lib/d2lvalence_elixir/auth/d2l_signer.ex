defmodule D2lvalenceElixir.Auth.D2LSigner do
  @moduledoc """
  Default signer module that app and user contexts can use to create appropiately signed tokens
  """

  @spec get_hash(
          String.t(),
          String.t()
        ) :: String.t()
  @doc ~S"""
  Get a digest value suitable for direct inclusion into an URL's query parameter as a token.

  Note that Valence API services expect signatures to be generated with the following constraints:
    - Encoding keys, and base strings, are UTF-8 encoded
    - HMAC digests are generated using a standard SHA-256 hash
    - Digests are then "URL-safe" base64 encoded (where `-` and `_` substitute for `+` and `/`)
    - The resulting string is then stripped of all `=` characters, and all leading and trailing whitespace characters

  `key_string` and `base_string` must be utf-8 encoded

  ## Examples

      iex> D2lvalenceElixir.Auth.D2LSigner.get_hash([104, 111, 108, 97, 195, 177], "hola")
      qauJsGg4cG2iTriPq1N1cfElwYDs3vIATlNwIbFqUM0

      iex> D2lvalenceElixir.Auth.D2LSigner.get_hash("hola", "hola")
      hj6sobenlkIElwSJKch0LgaPYU-fP3vlScIoWz-pN6U

  """
  def get_hash(key_string, base_string) do
    :crypto.mac(:hmac, :sha256, key_string, base_string)
    |> Base.encode64()
    |> String.replace("=", "")
    |> String.replace("+", "-")
    |> String.replace("/", "_")
    |> String.trim()
  end

  @spec check_hash(String.t(), String.t(), String.t()) :: boolean
  @doc """
  Verify that a given digest value was produced by a compatible `D2LSigner` given your provided base string and key.

  `key_string` and `base_string` must be utf-8 encoded

  ## Examples

      iex> D2lvalenceElixir.Auth.D2LSigner.check_hash("qauJsGg4cG2iTriPq1N1cfElwYDs3vIATlNwIbFqUM0", [104, 111, 108, 97, 195, 177], "hola")
      true

      iex> D2lvalenceElixir.Auth.D2LSigner.check_hash("hj6sobenlkIElwSJKch0LgaPYU-fP3vlScIoWz-pN6U", "hola", "hola")
      true

  """
  def check_hash(hash_string, key_string, base_string) do
    get_hash(key_string, base_string) == hash_string
  end
end
