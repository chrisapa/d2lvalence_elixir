defmodule D2lvalenceElixir.Auth do
  @moduledoc """
  Provides auth assistance for Desire2Learn's Valence API client applications.
  """

  ### Authentication ###
  # For use with D2LSigner

  # For use with D2LAppContext and D2LUserContext

  # For use with D2LUserContext

  # factory functions

  @spec fashion_app_context(%{app_id: String.t(), app_key: String.t()} | []) ::
          %D2lvalenceElixir.Auth.D2LAppContext{
            app_id: binary,
            app_key: binary
          }
  @doc """
  Build a new application context.

  :param app_id: D2L-provided Application ID string.

  :param app_key: D2L-provided Application Key string, used for signing.
  """
  def fashion_app_context(options \\ []) do
    defaults = [app_id: "", app_key: ""]

    options = Keyword.merge(defaults, options) |> Enum.into(%{})

    %{app_id: app_id, app_key: app_key} = options

    D2lvalenceElixir.Auth.D2LAppContext.new(app_id, app_key)
  end

  @spec fashion_user_context(
          %{app_id: String.t(), app_key: String.t(), d2l_user_context_props_dict: %{}}
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
  def fashion_user_context(options \\ []) do
    defaults = [app_id: "", app_key: "", d2l_user_context_props_dict: %{}]

    options = Keyword.merge(defaults, options) |> Enum.into(%{})

    %{app_id: app_id, app_key: app_key, d2l_user_context_props_dict: d2l_user_context_props_dict} =
      options

    ac = fashion_app_context(app_id: app_id, app_key: app_key)

    D2lvalenceElixir.Auth.D2LAppContext.create_user_context(ac,
      d2l_user_context_props_dict: d2l_user_context_props_dict
    )
  end
end
