defmodule D2lvalenceElixir.Data do
  @moduledoc """
  Provides definitions and support for handling Valence data structures
  """
  defmodule SupportedVersionRequest do
    @enforce_keys [:product_code, :version]
    defstruct [:product_code, :version]

    def brightspace_format(%D2lvalenceElixir.Data.SupportedVersionRequest{
          product_code: product_code,
          version: version
        }) do
      %{"ProductCode" => product_code, "Version" => version}
    end
  end

  defmodule UserData do
    @enforce_keys [
      :org_id,
      :user_id,
      :first_name,
      :middle_name,
      :last_name,
      :user_name,
      :external_email,
      :org_defined_id,
      :unique_identifier,
      :activation,
      :is_active
    ]

    defstruct [
      :org_id,
      :user_id,
      :first_name,
      :middle_name,
      :last_name,
      :user_name,
      :external_email,
      :org_defined_id,
      :unique_identifier,
      :activation,
      :is_active
    ]

    def new(information \\ %{}) when is_map(information) do
      %D2lvalenceElixir.Data.UserData{
        org_id: Map.get(information, "OrgId", -1),
        user_id: Map.get(information, "UserId", -1),
        first_name: Map.get(information, "FirstName", ""),
        middle_name: Map.get(information, "MiddleName", ""),
        last_name: Map.get(information, "LastName", ""),
        user_name: Map.get(information, "UserName", ""),
        external_email: Map.get(information, "ExternalEmail", ""),
        org_defined_id: Map.get(information, "OrgDefinedId", ""),
        unique_identifier: Map.get(information, "UniqueIdentifier", ""),
        activation: Map.get(information, "Activation", %{}),
        is_active: Map.get(information, "Activation", %{}) |> Map.get("IsActive", false)
      }
    end
  end

  defmodule PagedResultSet do
    @enforce_keys [:has_more_items, :paging_info, :bookmark, :items]
    defstruct [:has_more_items, :paging_info, :bookmark, :items]

    def new(information \\ %{}) when is_map(information) do
      %D2lvalenceElixir.Data.PagedResultSet{
        has_more_items: Map.get(information, "PagingInfo", %{}) |> Map.get("HasMoreItems", false),
        paging_info: Map.get(information, "PagingInfo", %{}),
        bookmark: Map.get(information, "PagingInfo", %{}) |> Map.get("Bookmark", ""),
        items: Map.get(information, "Items", [])
      }
    end
  end

  defmodule WhoAmIUser do
    @enforce_keys [:identifier, :first_name, :last_name, :unique_name, :profile_identifier]
    defstruct [:identifier, :first_name, :last_name, :unique_name, :profile_identifier]

    def new(information \\ %{}) when is_map(information) do
      %D2lvalenceElixir.Data.WhoAmIUser{
        identifier: Map.get(information, "Identifier", ""),
        first_name: Map.get(information, "FirstName", ""),
        last_name: Map.get(information, "LastName", ""),
        unique_name: Map.get(information, "UniqueName", ""),
        profile_identifier: Map.get(information, "ProfileIdentifier", "")
      }
    end
  end

  defmodule CreateUserData do
    @enforce_keys [
      :org_defined_id,
      :first_name,
      :middle_name,
      :last_name,
      :external_email,
      :user_name,
      :role_id,
      :is_active,
      :send_creation_email
    ]

    defstruct [
      :org_defined_id,
      :first_name,
      :middle_name,
      :last_name,
      :external_email,
      :user_name,
      :role_id,
      :is_active,
      :send_creation_email
    ]

    def brightspace_format(%D2lvalenceElixir.Data.CreateUserData{
          org_defined_id: org_defined_id,
          first_name: first_name,
          middle_name: middle_name,
          last_name: last_name,
          external_email: external_email,
          user_name: user_name,
          role_id: role_id,
          is_active: is_active,
          send_creation_email: send_creation_email
        }) do
      %{
        OrgDefinedId: org_defined_id,
        FirstName: first_name,
        MiddleName: middle_name,
        LastName: last_name,
        ExternalEmail: external_email,
        UserName: user_name,
        RoleId: role_id,
        IsActive: is_active,
        SendCreationEmail: send_creation_email
      }
    end

    def new(information \\ []) when is_list(information) do
      defaults = [
        org_defined_id: "",
        first_name: "",
        middle_name: "",
        last_name: "",
        external_email: nil,
        user_name: "",
        role_id: "",
        is_active: false,
        send_creation_email: false
      ]

      information_full = Keyword.merge(defaults, information) |> Enum.into(%{})

      %D2lvalenceElixir.Data.CreateUserData{
        org_defined_id: information_full.org_defined_id,
        first_name: information_full.first_name,
        middle_name: information_full.middle_name,
        last_name: information_full.last_name,
        external_email: information_full.external_email,
        user_name: information_full.user_name,
        role_id: information_full.role_id,
        is_active: information_full.is_active,
        send_creation_email: information_full.send_creation_email
      }
    end
  end

  defmodule UpdateUserData do
    @enforce_keys [
      :org_defined_id,
      :first_name,
      :middle_name,
      :last_name,
      :external_email,
      :user_name,
      :activation
    ]
    defstruct [
      :org_defined_id,
      :first_name,
      :middle_name,
      :last_name,
      :external_email,
      :user_name,
      :activation
    ]

    def new(information \\ []) when is_list(information) do
      defaults = [
        org_defined_id: "",
        first_name: "",
        middle_name: "",
        last_name: "",
        external_email: nil,
        user_name: "",
        activation: %{is_active: false}
      ]

      information_full = Keyword.merge(defaults, information) |> Enum.into(%{})

      %D2lvalenceElixir.Data.UpdateUserData{
        org_defined_id: information_full.org_defined_id,
        first_name: information_full.first_name,
        middle_name: information_full.middle_name,
        last_name: information_full.last_name,
        external_email: information_full.external_email,
        user_name: information_full.user_name,
        activation: information_full.activation
      }
    end

    def brightspace_format(%D2lvalenceElixir.Data.UpdateUserData{
          org_defined_id: org_defined_id,
          first_name: first_name,
          middle_name: middle_name,
          last_name: last_name,
          external_email: external_email,
          user_name: user_name,
          activation: %{is_active: is_active}
        }) do
      %{
        "OrgDefinedId" => org_defined_id,
        "FirstName" => first_name,
        "MiddleName" => middle_name,
        "LastName" => last_name,
        "ExternalEmail" => external_email,
        "UserName" => user_name,
        "Activation" => %{"IsActive" => is_active}
      }
    end
  end

  defmodule GradeObject do
    @enforce_keys [:id, :grade_type, :name, :short_name, :category, :description]
    defstruct [:id, :grade_type, :name, :short_name, :category, :description]

    def new(information \\ %{}) when is_map(information) do
      %D2lvalenceElixir.Data.GradeObject{
        id: Map.get(information, "Id", -1),
        grade_type: "",
        name: Map.get(information, "Name", ""),
        short_name: Map.get(information, "ShortName", ""),
        category: Map.get(information, "Category", ""),
        description: Map.get(information, "Description", "")
      }
    end
  end

  defmodule GradeObjectText do
    @enforce_keys [:id, :grade_type, :name, :short_name, :category, :description]
    defstruct [:id, :grade_type, :name, :short_name, :category, :description]

    def new(information \\ %{}) when is_map(information) do
      %D2lvalenceElixir.Data.GradeObjectText{
        id: Map.get(information, "Id", -1),
        grade_type: "Text",
        name: Map.get(information, "Name", ""),
        short_name: Map.get(information, "ShortName", ""),
        category: Map.get(information, "Category", ""),
        description: Map.get(information, "Description", "")
      }
    end
  end

  defmodule GradeObjectSelectBox do
    @enforce_keys [
      :id,
      :grade_type,
      :name,
      :short_name,
      :category,
      :description,
      :max_points,
      :is_bonus,
      :exclude_from_final_grade_calculation,
      :grade_scheme_id
    ]
    defstruct [
      :id,
      :grade_type,
      :name,
      :short_name,
      :category,
      :description,
      :max_points,
      :is_bonus,
      :exclude_from_final_grade_calculation,
      :grade_scheme_id
    ]

    def new(information \\ %{}) when is_map(information) do
      %D2lvalenceElixir.Data.GradeObjectSelectBox{
        id: Map.get(information, "Id", -1),
        grade_type: "SelectBox",
        name: Map.get(information, "Name", ""),
        short_name: Map.get(information, "ShortName", ""),
        category: Map.get(information, "Category", ""),
        description: Map.get(information, "Description", ""),
        max_points: Map.get(information, "MaxPoints", ""),
        is_bonus: Map.get(information, "IsBonus", ""),
        exclude_from_final_grade_calculation:
          Map.get(information, "ExcludeFromFinalGradeCalculation", ""),
        grade_scheme_id: Map.get(information, "GradeSchemeId", "")
      }
    end
  end

  defmodule GradeObjectPassFail do
    @enforce_keys [
      :id,
      :grade_type,
      :name,
      :short_name,
      :category,
      :description,
      :max_points,
      :is_bonus,
      :exclude_from_final_grade_calculation,
      :grade_scheme_id
    ]
    defstruct [
      :id,
      :grade_type,
      :name,
      :short_name,
      :category,
      :description,
      :max_points,
      :is_bonus,
      :exclude_from_final_grade_calculation,
      :grade_scheme_id
    ]

    def new(information \\ %{}) when is_map(information) do
      %D2lvalenceElixir.Data.GradeObjectPassFail{
        id: Map.get(information, "Id", -1),
        grade_type: "PassFail",
        name: Map.get(information, "Name", ""),
        short_name: Map.get(information, "ShortName", ""),
        category: Map.get(information, "Category", ""),
        description: Map.get(information, "Description", ""),
        max_points: Map.get(information, "MaxPoints", ""),
        is_bonus: Map.get(information, "IsBonus", ""),
        exclude_from_final_grade_calculation:
          Map.get(information, "ExcludeFromFinalGradeCalculation", ""),
        grade_scheme_id: Map.get(information, "GradeSchemeId", "")
      }
    end
  end

  defmodule GradeObjectNumeric do
    @enforce_keys [
      :id,
      :grade_type,
      :name,
      :short_name,
      :category,
      :description,
      :max_points,
      :can_exceed_max_points,
      :is_bonus,
      :exclude_from_final_grade_calculation,
      :grade_scheme_id
    ]

    defstruct [
      :id,
      :grade_type,
      :name,
      :short_name,
      :category,
      :description,
      :max_points,
      :can_exceed_max_points,
      :is_bonus,
      :exclude_from_final_grade_calculation,
      :grade_scheme_id
    ]

    def new(information \\ %{}) when is_map(information) do
      %D2lvalenceElixir.Data.GradeObjectNumeric{
        id: Map.get(information, "Id", -1),
        grade_type: "Numeric",
        name: Map.get(information, "Name", ""),
        short_name: Map.get(information, "ShortName", ""),
        category: Map.get(information, "Category", ""),
        description: Map.get(information, "Description", ""),
        max_points: Map.get(information, "MaxPoints", -1),
        can_exceed_max_points: Map.get(information, "CanExceedMaxPoints", false),
        is_bonus: Map.get(information, "IsBonus", false),
        exclude_from_final_grade_calculation:
          Map.get(information, "ExcludeFromFinalGradeCalculation", false),
        grade_scheme_id: Map.get(information, "GradeSchemeId", -1)
      }
    end
  end

  defmodule GradeValue do
    @enforce_keys [
      :displayed_grade,
      :grade_object_identifier,
      :grade_object_name,
      :grade_object_type,
      :grade_object_type_name
    ]
    defstruct [
      :displayed_grade,
      :grade_object_identifier,
      :grade_object_name,
      :grade_object_type,
      :grade_object_type_name
    ]

    def new(information \\ %{}) when is_map(information) do
      %D2lvalenceElixir.Data.GradeValue{
        displayed_grade: Map.get(information, "DisplayedGrade", -1),
        grade_object_identifier: Map.get(information, "GradeObjectIdentifier", -1),
        grade_object_name: Map.get(information, "GradeObjectName", -1),
        grade_object_type: Map.get(information, "GradeObjectType", -1),
        grade_object_type_name: Map.get(information, "GradeObjectTypeName", -1)
      }
    end
  end

  defmodule GradeValueComputable do
    @enforce_keys [
      :displayed_grade,
      :grade_object_identifier,
      :grade_object_name,
      :grade_object_type,
      :grade_object_type_name,
      :points_numerator,
      :points_denominator,
      :weighted_numerator,
      :weighted_denominator
    ]
    defstruct [
      :displayed_grade,
      :grade_object_identifier,
      :grade_object_name,
      :grade_object_type,
      :grade_object_type_name,
      :points_numerator,
      :points_denominator,
      :weighted_numerator,
      :weighted_denominator
    ]

    def new(information \\ %{}) when is_map(information) do
      %D2lvalenceElixir.Data.GradeValueComputable{
        displayed_grade: Map.get(information, "DisplayedGrade", -1),
        grade_object_identifier: Map.get(information, "GradeObjectIdentifier", -1),
        grade_object_name: Map.get(information, "GradeObjectName", -1),
        grade_object_type: Map.get(information, "GradeObjectType", -1),
        grade_object_type_name: Map.get(information, "GradeObjectTypeName", -1),
        points_numerator: Map.get(information, "PointsNumerator", -1),
        points_denominator: Map.get(information, "PointsDenominator", -1),
        weighted_numerator: Map.get(information, "WeightedNumerator", -1),
        weighted_denominator: Map.get(information, "WeightedDenominator", -1)
      }
    end
  end

  defmodule ClasslistUser do
    @enforce_keys [
      :identifier,
      :profile_identifier,
      :display_name,
      :user_name,
      :org_defined_id,
      :email
    ]
    defstruct [
      :identifier,
      :profile_identifier,
      :display_name,
      :user_name,
      :org_defined_id,
      :email
    ]

    def new(information \\ %{}) when is_map(information) do
      %D2lvalenceElixir.Data.ClasslistUser{
        identifier: Map.get(information, "Identifier", ""),
        profile_identifier: Map.get(information, "ProfileIdentifier", ""),
        display_name: Map.get(information, "DisplayName", ""),
        user_name: Map.get(information, "UserName", ""),
        org_defined_id: Map.get(information, "OrgDefinedId", ""),
        email: Map.get(information, "Email", "")
      }
    end
  end
end
