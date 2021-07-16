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

  defmodule DropboxFolder do
    @enforce_keys [
      :assessment,
      :attachments,
      :availability,
      :category_id,
      :custom_instructions,
      :display_in_calendar,
      :due_date,
      :flagged_files,
      :groupe_type_id,
      :id,
      :is_hidden,
      :name,
      :notification_email,
      :total_files,
      :total_users,
      :total_users_with_feedback,
      :total_users_with_submissions,
      :unread_files
    ]

    defstruct [
      :assessment,
      :attachments,
      :availability,
      :category_id,
      :custom_instructions,
      :display_in_calendar,
      :due_date,
      :flagged_files,
      :groupe_type_id,
      :id,
      :is_hidden,
      :name,
      :notification_email,
      :total_files,
      :total_users,
      :total_users_with_feedback,
      :total_users_with_submissions,
      :unread_files
    ]

    def new(information \\ %{}) when is_map(information) do
      %D2lvalenceElixir.Data.DropboxFolder{
        assessment:
          Map.get(information, "Assessment", %{})
          |> then(fn
            map when map_size(map) == 0 ->
              nil

            map ->
              %{}
              |> Map.put(:rubrics, map |> Map.get("Rubrics", []))
              |> Map.put(:score_denominator, map |> Map.get("ScoreDenominator", 0))
          end),
        attachments:
          Map.get(information, "Attachments", [])
          |> Enum.map(fn attachment ->
            %{}
            |> Map.put(:file_id, attachment |> Map.get("FileId", -1))
            |> Map.put(:file_name, attachment |> Map.get("FileName", ""))
            |> Map.put(:size, attachment |> Map.get("Size", -1))
          end),
        availability:
          Map.get(information, "Availability", %{})
          |> then(fn
            map when map_size(map) == 0 ->
              nil

            map ->
              %{}
              |> Map.put(:end_date, map |> Map.get("EndDate", nil))
              |> Map.put(:start_date, map |> Map.get("StartDate", nil))
          end),
        category_id: Map.get(information, "CategoryId", nil),
        custom_instructions:
          Map.get(information, "CustomInstructions", %{})
          |> then(fn
            map when map_size(map) == 0 ->
              nil

            map ->
              %{}
              |> Map.put(:html, map |> Map.get("Html", ""))
              |> Map.put(:text, map |> Map.get("Text", ""))
          end),
        display_in_calendar: Map.get(information, "DisplayInCalendar", false),
        due_date: Map.get(information, "DueDate", nil),
        flagged_files: Map.get(information, "FlaggedFiles", -1),
        groupe_type_id: Map.get(information, "GroupTypeId", nil),
        id: Map.get(information, "Id", -1),
        is_hidden: Map.get(information, "IsHidden", false),
        name: Map.get(information, "Name", ""),
        notification_email: Map.get(information, "NotificationEmail", nil),
        total_files: Map.get(information, "TotalFiles", -1),
        total_users: Map.get(information, "TotalUsers", -1),
        total_users_with_feedback: Map.get(information, "TotalUsersWithFeedback", -1),
        total_users_with_submissions: Map.get(information, "TotalUsersWithSubmissions", -1),
        unread_files: Map.get(information, "UnreadFiles", -1)
      }
    end
  end

  defmodule SubmissionsForDropbox do
    @enforce_keys [:completion_date, :entity, :feedback, :status, :submissions]
    defstruct [:completion_date, :entity, :feedback, :status, :submissions]

    def new(information \\ %{}) when is_map(information) do
      %D2lvalenceElixir.Data.SubmissionsForDropbox{
        completion_date: Map.get(information, "CompletionDate", nil),
        entity:
          Map.get(information, "Entity", %{})
          |> then(fn
            map when map_size(map) == 0 ->
              nil

            map ->
              %{}
              |> Map.put(:active, map |> Map.get("Active", false))
              |> Map.put(:display_name, map |> Map.get("DisplayName", ""))
              |> Map.put(:entity_id, map |> Map.get("EntityId", -1))
              |> Map.put(:entity_type, map |> Map.get("EntityType", ""))
          end),
        feedback:
          Map.get(information, "Feedback", %{})
          |> then(fn
            map when map_size(map) == 0 ->
              nil

            map ->
              %{}
              |> Map.put(:feedback, map |> Map.get("Feedback", %{}))
              |> Map.put(:files, map |> Map.get("Files", []))
              |> Map.put(:graded_symbol, map |> Map.get("GradedSymbol", nil))
              |> Map.put(:is_graded, map |> Map.get("IsGraded", false))
              |> Map.put(:rubric_assessments, map |> Map.get("RubricAssessments", false))
              |> Map.put(:score, map |> Map.get("Score", false))
          end),
        status: Map.get(information, "Status", -1),
        submissions:
          Map.get(information, "Submissions", [])
          |> Enum.map(fn map ->
            D2lvalenceElixir.Data.SingleSubmissionForDropbox.new(map)
          end)
      }
    end
  end

  defmodule SingleSubmissionForDropbox do
    @enforce_keys [:comment, :files, :id, :submission_date, :submitted_by]
    defstruct [:comment, :files, :id, :submission_date, :submitted_by]

    def new(information \\ %{}) when is_map(information) do
      %D2lvalenceElixir.Data.SingleSubmissionForDropbox{
        comment:
          information
          |> Map.get("Comment", %{})
          |> then(fn
            map ->
              %{}
              |> Map.put(:html, map |> Map.get("Html", %{}))
              |> Map.put(:text, map |> Map.get("Text", %{}))
          end),
        files:
          information
          |> Map.get("Files", [])
          |> Enum.map(fn map -> D2lvalenceElixir.Data.SubmissionFile.new(map) end),
        id: information |> Map.get("Id", -1),
        submission_date: information |> Map.get("SubmissionDate", nil),
        submitted_by:
          information
          |> Map.get("SubmittedBy", %{})
          |> then(fn map ->
            %{}
            |> Map.put(:display_name, map |> Map.get("DisplayName", ""))
            |> Map.put(:identifier, map |> Map.get("Identifier", ""))
          end)
      }
    end
  end

  defmodule SubmissionFile do
    @enforce_keys [:file_id, :file_name, :is_deleted, :is_flagged, :is_read, :size]
    defstruct [:file_id, :file_name, :is_deleted, :is_flagged, :is_read, :size]

    def new(information \\ %{}) when is_map(information) do
      %D2lvalenceElixir.Data.SubmissionFile{
        file_id: information |> Map.get("FileId", -1),
        file_name: information |> Map.get("FileName", ""),
        is_deleted: information |> Map.get("IsDeleted", false),
        is_flagged: information |> Map.get("IsFlagged", false),
        is_read: information |> Map.get("IsRead", false),
        size: information |> Map.get("Size", -1)
      }
    end
  end

  defmodule FileResponse do
    @moduledoc """
    Downloaded files are stored in a temporary directory. It's recommended to delete this file after the download and copy.

    During the requests, files are represented with a D2lvalenceElixir.Data.FileResponse struct that contains two fields:

    - `:path` - the path to the downloaded file on the filesystem
    - `:filename` - the original filename of the downloaded file

    """
    @enforce_keys [:filename, :path]
    defstruct [:filename, :path]

    def new(information \\ []) when is_list(information) do
      defaults = [
        filename: "",
        path: ""
      ]

      %{filename: filename, path: path} = Keyword.merge(defaults, information) |> Enum.into(%{})

      %D2lvalenceElixir.Data.FileResponse{
        filename: filename,
        path: path
      }
    end
  end
end
