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
         headers,
         body
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
         options
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
         body
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
         body
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
          headers: [{"Content-Type", "application/json"}],
          body: body
        )
    end
  end

  defp put(
         route,
         user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
         serializers,
         body
       ) do
    case user_context.anonymous do
      true ->
        {:error, "User context cannot be anonymous"}

      false ->
        do_request(
          :put,
          route,
          user_context,
          "application/json",
          serializers,
          headers: [{"Content-Type", "application/json"}],
          body: body
        )
    end
  end

  defp get_anon(
         route,
         user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
         serializers,
         body
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
         body
       ) do
    do_request(
      :post,
      route,
      user_context,
      "application/json",
      serializers,
      headers: [{"Content-Type", "application/json"}],
      body: body
    )
  end

  ## TODO - For future releases
  defp simple_upload(
         _route,
         _user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
         _f,
         _serializers,
         _body \\ []
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

  ## Returns
  `{:error, cause}` when an error is caused.

  `{:ok, list(map())}` If application/json serializer available returns a list of maps with the check of every product.

  ## Parameters
  `supported_version_request_list` must be a list of `%D2lvalenceElixir.Data.SupportedVersionRequest{}`

  ## Options
  serializers: Map of availaber serializers. application/json recommended.
  body: Options to pass to the body of the request.
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
        body
        |> Enum.concat(
          supported_version_request_list
          |> Enum.map(fn %D2lvalenceElixir.Data.SupportedVersionRequest{} = supported_request ->
            D2lvalenceElixir.Data.SupportedVersionRequest.brightspace_format(supported_request)
          end)
        )

        "/d2l/api/versions/check"
        |> post_anon(user_context, serializers, body)
    end
  end

  # User functions
  # User data

  @spec delete_user(
          %D2lvalenceElixir.Auth.D2LUserContext{},
          String.t(),
          %{serializers: map() | %{}, body: map() | %{}, ver: String.t()}
        ) :: {:error, String.t()} | {:ok, any}
  @doc """
  Deletes the user with the user_id.

  ## Returns
  `{:error, cause}` when an error is caused.

  `{:ok, body_parsed}` the body_parsed depends on the available serializers.

  ## Parameters
  `supported_version_request_list` must be a list of `%D2lvalenceElixir.Data.SupportedVersionRequest{}`

  ## Options
  serializers: Map of availaber serializers. application/json recommended.
  body: Options to pass to the body of the request.
  """
  def delete_user(
        user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
        user_id,
        options \\ []
      ) do
    defaults = [ver: "1.0", serializers: %{}, body: []]

    %{serializers: serializers, body: body, ver: ver} =
      Keyword.merge(defaults, options) |> Enum.into(%{})

    "/d2l/api/lp/#{ver}/users/#{user_id}"
    |> delete(user_context, serializers, body)
  end

  @spec get_users(
          %D2lvalenceElixir.Auth.D2LUserContext{},
          serializers: map() | %{},
          body: list() | [],
          ver: String.t(),
          org_defined_id: String.t(),
          user_name: String.t(),
          bookmark: String.t()
        ) ::
          {:error, String.t()}
          | {:ok, %D2lvalenceElixir.Data.UserData{}}
          | {:ok, list(%D2lvalenceElixir.Data.UserData{})}
          | {:ok, %D2lvalenceElixir.Data.PagedResultSet{}}
  @doc """
  Get the users information.

  ## Returns
  `{:error, cause}` when an error is caused.

  `{:ok, list(%D2lvalenceElixir.Data.UserData{})}` when the org_defined_id is defined.

  `{:ok, %D2lvalenceElixir.Data.UserData{}}` when the user_name is defined and the org_defined_id is not defined.

  `{:ok, %D2lvalenceElixir.Data.PagedResultSer{}}` when only the bookmark is defined.

  ## Options
  serializers: Map of availaber serializers. application/json recommended.
  body: Options to pass to the body of the request.
  org_defined_id: Id of the organization.
  user_name: User name to obtain the information
  bookmark: Bookmark for the request
  """
  def get_users(user_context = %D2lvalenceElixir.Auth.D2LUserContext{}, options \\ []) do
    defaults = [
      ver: "1.0",
      org_defined_id: nil,
      user_name: nil,
      bookmark: nil,
      serializers: %{},
      body: []
    ]

    %{
      serializers: serializers,
      body: body,
      ver: ver,
      org_defined_id: org_defined_id,
      user_name: user_name,
      bookmark: bookmark
    } = Keyword.merge(defaults, options) |> Enum.into(%{})

    body_with_information =
      body
      |> Enum.into(%{})
      |> then(fn body ->
        case bookmark do
          nil ->
            body

          bookmark ->
            body
            |> Map.put("bookmark", bookmark)
        end
      end)
      |> then(fn body ->
        case user_name do
          nil ->
            body

          user_name ->
            body
            |> Map.put("userName", user_name)
        end
      end)
      |> then(fn body ->
        case org_defined_id do
          nil ->
            body

          org_defined_id ->
            body
            |> Map.put("orgDefinedId", org_defined_id)
        end
      end)
      |> Map.to_list()

    "/d2l/api/lp/#{ver}/users/"
    |> get(user_context, serializers, body_with_information)
    |> then(fn
      {:ok, result} ->
        cond do
          org_defined_id != nil ->
            {:ok,
             result
             |> Enum.map(fn user_information ->
               D2lvalenceElixir.Data.UserData.new(user_information)
             end)}

          user_name != nil ->
            {:ok,
             result
             |> D2lvalenceElixir.Data.UserData.new()}

          true ->
            {:ok, result |> D2lvalenceElixir.Data.PagedResultSet.new()}
        end

      {:error, cause} ->
        {:error, cause}
    end)
  end

  @spec get_user(
          %D2lvalenceElixir.Auth.D2LUserContext{},
          String.t(),
          keyword
        ) :: {:error, String.t()} | {:ok, %D2lvalenceElixir.Data.UserData{}}
  @doc """
  Get the information of an user.

  ## Returns
  `{:error, cause}` when an error is caused.

  `{:ok, %D2lvalenceElixir.Data.UserData{}}` with the information requested

  ## Options
  serializers: Map of availaber serializers. application/json recommended.
  body: Options to pass to the body of the request.
  """
  def get_user(user_context = %D2lvalenceElixir.Auth.D2LUserContext{}, user_id, options \\ []) do
    defaults = [
      ver: "1.0",
      serializers: %{},
      body: []
    ]

    %{
      serializers: serializers,
      body: body,
      ver: ver
    } = Keyword.merge(defaults, options) |> Enum.into(%{})

    "/d2l/api/lp/#{ver}/users/#{user_id}"
    |> get(user_context, serializers, body)
    |> case do
      {:ok, result} ->
        {:ok,
         result
         |> D2lvalenceElixir.Data.UserData.new()}

      result ->
        result
    end
  end

  @spec get_whoami(
          %D2lvalenceElixir.Auth.D2LUserContext{},
          %{serializers: %{}, ver: String.t()}
        ) :: {:error, String.t()} | {:ok, %D2lvalenceElixir.Data.WhoAmIUser{}}
  @doc """
  Calls the Whoami service of Brightspace.

  ## Returns
  `{:error, cause}` when an error is caused.

  `{:ok, %D2lvalenceElixir.Data.WhoAmIUser{}}` the result contains the information of the logged user.

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
    |> case do
      {:ok, result} ->
        {:ok, result |> D2lvalenceElixir.Data.WhoAmIUser.new()}

      result ->
        result
    end
  end

  @spec create_user(
          %D2lvalenceElixir.Auth.D2LUserContext{},
          %D2lvalenceElixir.Data.CreateUserData{},
          serializers: map(),
          ver: String.t(),
          body: list()
        ) :: {:error, String.t()} | {:ok, %D2lvalenceElixir.Data.UserData{}}
  @doc """
    Creates the user with the information provided.

  ## Returns
  `{:error, cause}` when an error is caused.

  `{:ok, %D2lvalenceElixir.Data.UserData{}}` the result contains the information created.

  ## Options
  version: version of the component to verify. If not specified, will get the version of the component.
  serializers: Map of availaber serializers. application/json recommended.
  body: Options to pass to the body of the request.
  """
  def create_user(
        user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
        create_user_data = %D2lvalenceElixir.Data.CreateUserData{},
        options \\ []
      ) do
    defaults = [
      serializers: %{},
      ver: "1.0",
      body: []
    ]

    options = Keyword.merge(defaults, options) |> Enum.into(%{})

    %{serializers: serializers, ver: ver, body: body} = options

    full_body =
      body
      |> Enum.into(%{})
      |> Map.merge(create_user_data |> D2lvalenceElixir.Data.CreateUserData.brightspace_format())
      |> Map.to_list()

    "/d2l/api/lp/#{ver}/users/"
    |> post(user_context, serializers, full_body)
    |> D2lvalenceElixir.Data.UserData.new()
  end

  @spec update_user(
          %D2lvalenceElixir.Auth.D2LUserContext{},
          String.t(),
          %D2lvalenceElixir.Data.UpdateUserData{},
          serializers: map(),
          ver: String.t(),
          body: list()
        ) :: {:error, String.t()} | {:ok, any}
  @doc """
  Creates the user with the information provided.

  ## Returns
  `{:error, cause}` when an error is caused.

  `{:ok, %D2lvalenceElixir.Data.UserData{}}` the result contains the information created.

  ## Options
  version: version of the component to verify. If not specified, will get the version of the component.
  serializers: Map of availaber serializers. application/json recommended.
  body: Options to pass to the body of the request.
  """
  def update_user(
        user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
        user_id,
        update_user_data = %D2lvalenceElixir.Data.UpdateUserData{},
        options \\ []
      ) do
    defaults = [
      serializers: %{},
      ver: "1.0",
      body: []
    ]

    options = Keyword.merge(defaults, options) |> Enum.into(%{})

    %{serializers: serializers, ver: ver, body: body} = options

    full_body =
      body
      |> Enum.into(%{})
      |> Map.merge(update_user_data |> D2lvalenceElixir.Data.UpdateUserData.brightspace_format())
      |> Map.to_list()

    "/d2l/api/lp/#{ver}/users/#{user_id}"
    |> put(user_context, serializers, full_body)
  end

  # Activation

  """
  TODO
  get_user_activation
  update_user_activation
  """

  # Profiles

  """
  TODO
  def delete_my_profile_image
  def delete_profile_image_by_profile_id
  def delete_profile_image_by_user_id
  def get_profile_by_profile_id
  def get_profile_image_by_profile_id
  def get_profile_by_user_id
  def get_profile_image_by_user_id
  def get_my_profile
  def get_my_profile_image
  def update_my_profile
  def update_profile_image_by_user_id
  def update_profile_image_by_profile_id
  def update_my_profile_image
  """

  # Passwords

  """
  TODO
  def delete_password_for_user
  def send_password_reset_email_for_user
  def update_password_for_user
  """

  # Roles

  """
  TODO
  def get_all_roles
  def get_role
  """

  # Org structure

  """
  TODO
  def get_organization_info
  def get_orgunit_children
  def get_orgunit_descendants
  def get_orgunit_parents
  def get_orgunit_properties
  def create_custom_orgunit
  def update_custom_orgunit
  """

  # Org unit types

  """
  TODO
  def get_all_outypes
  def get_outype
  """

  # Enrollments

  @spec get_classlist(
          %D2lvalenceElixir.Auth.D2LUserContext{},
          integer(),
          serializers: map(),
          ver: String.t(),
          body: list()
        ) :: {:error, String.t()} | {:ok, list(%D2lvalenceElixir.Data.ClasslistUser{})}
  @doc """
  Get the classlist of an org unit id

  ## Returns
  `{:error, cause}` when an error is caused.

  `{:ok, list(%D2lvalenceElixir.Data.ClasslistUser{})}`
  The result contains the information of the classlist.

  ## Options
  version: version of the component to verify. If not specified, will get the version of the component.
  serializers: Map of availaber serializers. application/json recommended.
  body: Options to pass to the body of the request.
  """
  def get_classlist(
        user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
        org_unit_id,
        options \\ []
      ) do
    defaults = [
      serializers: %{},
      ver: "1.0",
      body: []
    ]

    %{serializers: serializers, ver: ver, body: body} =
      Keyword.merge(defaults, options) |> Enum.into(%{})

    "/d2l/api/le/#{ver}/#{org_unit_id}/classlist/"
    |> get(user_context, serializers, body)
    |> case do
      {:ok, result} ->
        {:ok,
         result
         |> Enum.map(fn result -> result |> D2lvalenceElixir.Data.ClasslistUser.new() end)}

      result ->
        result
    end
  end

  """
  TODO
  def delete_user_enrollment_in_orgunit
  def get_my_enrollments
  def get_enrolled_users_for_orgunit
  def get_enrolled_user_in_orgunit
  def get_all_enrollments_for_user
  def create_enrollment_for_user
  """

  # Groups

  """
  TODO
  def delete_group_category_from_orgunit
  def delete_group_from_orgunit
  def delete_user_from_group
  def get_group_categories_for_orgunit
  """

  # Course offerings

  """
  TODO
  def delete_course_offering
  def get_course_schemas
  def get_course_offering
  def create_course_offering
  def update_course_offering
  """

  # Course templates

  """
  TODO
  def delete_course_template
  def get_course_template
  def get_course_templates_schema
  def create_course_template
  def update_course_template
  """

  # Grades

  """
  TODO
  def delete_grade_object_for_org
  """

  @spec get_all_grade_objects_for_org(
          %D2lvalenceElixir.Auth.D2LUserContext{},
          integer(),
          serializers: map(),
          ver: String.t(),
          body: list()
        ) ::
          {:error, String.t()}
          | {:ok,
             list(
               %D2lvalenceElixir.Data.GradeObjectNumeric{}
               | %D2lvalenceElixir.Data.GradeObjectPassFail{}
               | %D2lvalenceElixir.Data.GradeObjectText{}
               | %D2lvalenceElixir.Data.GradeObject{}
             )}
  @doc """
  Get all the grade objects for the organization unit id.

  ## Returns
  `{:error, cause}` when an error is caused.

  `{:ok, list(%D2lvalenceElixir.Data.GradeObjectNumeric{} | %D2lvalenceElixir.Data.GradeObjectPassFail{} | %D2lvalenceElixir.Data.GradeObjectText{} | %D2lvalenceElixir.Data.GradeObject{})}`
  The result contains the information of the grade objects.

  ## Options
  version: version of the component to verify. If not specified, will get the version of the component.
  serializers: Map of availaber serializers. application/json recommended.
  body: Options to pass to the body of the request.
  """
  def get_all_grade_objects_for_org(
        user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
        org_unit_id,
        options \\ []
      ) do
    defaults = [
      serializers: %{},
      ver: "1.0",
      body: []
    ]

    options = Keyword.merge(defaults, options) |> Enum.into(%{})

    %{serializers: serializers, ver: ver, body: body} = options

    "/d2l/api/le/#{ver}/#{org_unit_id}/grades/"
    |> get(user_context, serializers, body)
    |> case do
      {:ok, result} ->
        {:ok,
         result
         |> Enum.map(fn result ->
           case Map.get(result, "GradeType") do
             "Numeric" ->
               result
               |> D2lvalenceElixir.Data.GradeObjectNumeric.new()

             "PassFail" ->
               result
               |> D2lvalenceElixir.Data.GradeObjectPassFail.new()

             "SelectBox" ->
               result
               |> D2lvalenceElixir.Data.GradeObjectSelectBox.new()

             "Text" ->
               result
               |> D2lvalenceElixir.Data.GradeObjectText.new()

             _ ->
               result
               |> D2lvalenceElixir.Data.GradeObject.new()
           end
         end)}

      result ->
        result
    end
  end

  """
  TODO
  def get_grade_object_for_org
  def create_grade_object_for_org
  def update_grade_object_for_org
  """

  # Grade categories

  """
  TODO
  def delete_grade_category_for_orgunit
  def get_all_grade_categories_for_orgunit
  def get_grade_category_for_orgunit
  def create_grade_category_for_orgunit
  """

  # Grade schemes

  """
  TODO
  def get_all_grade_schemes_for_orgunit
  def get_grade_scheme_for_orgunit
  # Grade values
  def get_my_final_grade_value_for_org
  def get_final_grade_value_for_user_in_org
  def get_grade_value_for_user_in_org
  def get_my_grade_value_for_org
  def get_all_my_grade_values_for_org
  """

  @spec get_all_grade_values_for_user_in_org(
          %D2lvalenceElixir.Auth.D2LUserContext{},
          integer(),
          integer(),
          serializers: map,
          ver: String.t(),
          body: list()
        ) ::
          {:error, String.t()}
          | {:ok,
             list(
               %D2lvalenceElixir.Data.GradeValueComputable{}
               | %D2lvalenceElixir.Data.GradeValue{}
             )}
  @doc """
  Get all the grades from the user.

  ## Returns
  `{:error, cause}` when an error is caused.

  `{:ok, list(%D2lvalenceElixir.Data.GradeValueComputable{}| %D2lvalenceElixir.Data.GradeValue{})}`
  The result contains the information of the grade objects.

  ## Options
  version: version of the component to verify. If not specified, will get the version of the component.
  serializers: Map of availaber serializers. application/json recommended.
  body: Options to pass to the body of the request.
  """
  def get_all_grade_values_for_user_in_org(
        user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
        org_unit_id,
        user_id,
        options \\ []
      ) do
    defaults = [
      serializers: %{},
      ver: "1.0",
      body: []
    ]

    options = Keyword.merge(defaults, options) |> Enum.into(%{})

    %{serializers: serializers, ver: ver, body: body} = options

    "/d2l/api/le/#{ver}/#{org_unit_id}/grades/values/#{user_id}/"
    |> get(user_context, serializers, body)
    |> case do
      {:ok, result} ->
        {:ok,
         result
         |> Enum.map(fn result ->
           cond do
             Map.has_key?(result, "PointsNumerator") ->
               result
               |> D2lvalenceElixir.Data.GradeValueComputable.new()

             true ->
               result
               |> D2lvalenceElixir.Data.GradeValue.new()
           end
         end)}

      result ->
        result
    end
  end

  """
  TODO
  def recalculate_final_grade_value_for_user_in_org
  def recalculate_all_final_grade_values_for_org
  def update_final_adjusted_grade_value_for_user_in_org
  def update_grade_value_for_user_in_org
  """

  # Course completion

  """
  TODO
  def delete_course_completion
  def get_all_course_completions_for_org
  def get_all_course_completions_for_user
  def create_course_completion_for_org
  def update_course_completion_for_org
  """

  # Dropbox

  @spec get_all_dropbox_folders_for_orgunit(
          %D2lvalenceElixir.Auth.D2LUserContext{},
          integer(),
          serializers: map(),
          ver: String.t(),
          body: list()
        ) :: {:error, String.t()} | {:ok, any}
  @doc """
  Gets all the folders of the orgunit.

  ## Returns
  `{:error, cause}` when an error is caused.

  `{:ok, list(%{})}`
  The result contains a list with all the folders of the orgunit.

  ## Options
  version: version of the component to verify. If not specified, will get the version of the component.
  serializers: Map of availaber serializers. application/json recommended.
  body: Options to pass to the body of the request.
  """
  def get_all_dropbox_folders_for_orgunit(
        user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
        org_unit_id,
        options \\ []
      ) do
    defaults = [
      serializers: %{},
      ver: "1.0",
      body: []
    ]

    %{serializers: serializers, ver: ver, body: body} =
      Keyword.merge(defaults, options) |> Enum.into(%{})

    "/d2l/api/le/#{ver}/#{org_unit_id}/dropbox/folders/"
    |> get(user_context, serializers, body)
  end

  """
  TODO
  def get_dropbox_folder_for_orgunit
  def create_my_submission_for_dropbox
  def create_submission_for_group_dropbox_folder
  """

  @spec get_submissions_for_dropbox_folder(
          %D2lvalenceElixir.Auth.D2LUserContext{},
          integer(),
          integer(),
          serializers: map(),
          ver: String.t(),
          body: list()
        ) :: {:error, String.t()} | {:ok, any}
  @doc """
  Get all the submissions from the dropbox folder

  ## Returns
  `{:error, cause}` when an error is caused.

  `{:ok, list(%{})}`
  The result contains a list with all the submissions of the dropbox folder.

  ## Options
  version: version of the component to verify. If not specified, will get the version of the component.
  serializers: Map of availaber serializers. application/json recommended.
  body: Options to pass to the body of the request.
  """
  def get_submissions_for_dropbox_folder(
        user_context = %D2lvalenceElixir.Auth.D2LUserContext{},
        org_unit_id,
        folder_id,
        options \\ []
      ) do
    defaults = [
      serializers: %{},
      ver: "1.0",
      body: []
    ]

    %{serializers: serializers, ver: ver, body: body} =
      Keyword.merge(defaults, options) |> Enum.into(%{})

    "/d2l/api/le/#{ver}/#{org_unit_id}/dropbox/folders/#{folder_id}/submissions/"
    |> get(user_context, serializers, body)
  end

  # Lockers

  """
  TODO
  def _get_locker_item
  def _check_path
  def delete_my_locker_item
  def delete_locker_item
  def get_my_locker_item
  def get_locker_item
  def create_my_locker_folder
  def create_locker_folder
  def create_my_locker_file
  def create_locker_file
  def rename_my_locker_folder
  def rename_locker_folder
  """

  # Lockers and groups

  """
  TODO
  def delete_group_locker_item
  def get_group_locker_category
  def get_group_locker_item
  def setup_group_locker_category
  def create_group_locker_folder
  def create_group_locker_file
  def rename_group_locker_folder
  """

  # Discussion forum routes

  """
  TODO
  def delete_discussion_forum
  def get_discussion_forums
  def get_discussion_forum
  def create_discussion_forum
  def update_discussion_forum
  """

  # Discussion topics

  """
  TODO
  def delete_discussion_topic
  def delete_discussion_topic_group_restriction
  def get_discussion_topics
  def get_discussion_topic
  def get_discussion_topics_group_restrictions
  def create_discussion_topic
  def update_discussion_topic
  def update_group_restrictions_list
  """

  # Discussion posts

  """
  TODO
  def delete_discussion_post
  def delete_my_rating_for_discussion_post
  def get_discussion_posts
  def get_discussion_post
  def get_discussion_post_approval_status
  def get_discussion_post_flag_status
  def get_discussion_post_rating
  def get_discussion_my_post_rating
  def get_discussion_post_read_status
  def create_discussion_post
  def update_discussion_post
  def set_discussion_post_approval_status
  def set_discussion_post_flag_status
  def set_discussion_post_my_rating
  def set_discussion_post_read_status
  """

  # News routes

  """
  TODO
  def get_my_feed(
  def delete_news_item_for_orgunit
  def delete_attachment_for_news_item_in_orgunit
  def get_news_for_orgunit
  def get_news_item_for_orgunit
  def get_news_item_attachment_for_orgunit
  def dismiss_news_item_for_orgunit
  def restore_news_item_for_orgunit
  def create_news_item_for_orgunit
  def create_attachment_for_newsitem
  """

  # Calendar routes

  """
  TODO
  def delete_calender_event_for_org
  def get_calendar_event_for_org
  def get_all_calendar_events_for_org
  """

  # Content routes

  """
  def delete_content_module
  def delete_content_topic
  def get_content_module
  def get_content_module_structure
  def get_content_root_modules
  def get_content_topic
  def create_content_new_module
  def create_content_new_topic_link
  def create_content_new_topic_file
  def create_content_root_module
  def update_content_module
  def update_content_topic
  """

  # Learning Repository routes

  """
  TODO
  def get_learning_objects_by_search
  def get_learning_object
  def get_learning_object_link
  def get_learning_object_properties
  def get_learning_object_version
  def get_learning_object_link_version
  def get_learning_object_metadata_version
  def get_learning_object_properties_version
  def delete_learning_object
  def update_learning_object
  def update_learning_object_properties
  def update_learning_object_properties_version
  def create_new_learning_object
  """

  # ePortfolio routes

  # eP import/export

  """
  TODO
  def get_ep_import_task_status
  def start_ep_import_task
  def start_ep_export_all_task
  def start_ep_export_task
  def get_ep_export_task_status
  def get_ep_export_task_package
  """

  # LTI routes

  # LTI links

  # LTI Tool providers

  """
  TODO
  def get_lti_tool_providers_for_orgunit
  def get_lti_tool_provider_info
  """
end
