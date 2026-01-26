require "test_helper"

class MedicalFoldersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @medical_folder = medical_folders(:one)
    sign_in_as(@user)
  end

  # ============ HTML Format Tests ============

  test "should get index" do
    get medical_folders_url
    assert_response :success
  end

  test "should get new" do
    get new_medical_folder_url
    assert_response :success
  end

  test "should create medical_folder" do
    assert_difference("MedicalFolder.count") do
      post medical_folders_url, params: {
        medical_folder: {
          name: "New Test Folder",
          specialty: "cardiology",
          description: "Test description"
        }
      }
    end

    assert_redirected_to medical_folder_url(MedicalFolder.last)
  end

  test "should show medical_folder" do
    get medical_folder_url(@medical_folder)
    assert_response :success
  end

  test "should get edit" do
    get edit_medical_folder_url(@medical_folder)
    assert_response :success
  end

  test "should update medical_folder" do
    patch medical_folder_url(@medical_folder), params: {
      medical_folder: { name: "Updated Name" }
    }
    assert_redirected_to medical_folder_url(@medical_folder)
  end

  test "should destroy medical_folder" do
    assert_difference("MedicalFolder.count", -1) do
      delete medical_folder_url(@medical_folder)
    end

    assert_redirected_to dashboard_url
  end

  # ============ JSON Format Tests (for PWA/Offline sync) ============

  test "should get index as JSON" do
    get medical_folders_url, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json.key?("folders")
    assert json.key?("synced_at")
    assert json["folders"].is_a?(Array)
  end

  test "should show medical_folder as JSON" do
    get medical_folder_url(@medical_folder), as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @medical_folder.id, json["id"]
    assert_equal @medical_folder.name, json["name"]
    assert_equal @medical_folder.specialty, json["specialty"]
    assert json.key?("specialty_name")
    assert json.key?("specialty_color")
    assert json.key?("documents_count")
    assert json.key?("created_at")
    assert json.key?("updated_at")
  end

  test "should show medical_folder with documents as JSON" do
    get medical_folder_url(@medical_folder), as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json.key?("documents")
    assert json["documents"].is_a?(Array)
  end

  test "should create medical_folder via JSON" do
    assert_difference("MedicalFolder.count") do
      post medical_folders_url,
        params: {
          medical_folder: {
            name: "JSON Created Folder",
            specialty: "neurology",
            description: "Created via JSON API"
          }
        },
        as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "JSON Created Folder", json["name"]
    assert_equal "neurology", json["specialty"]
  end

  test "should return errors when create fails via JSON" do
    post medical_folders_url,
      params: { medical_folder: { name: "", specialty: "" } },
      as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json.key?("errors")
    assert json["errors"].is_a?(Array)
  end

  test "should update medical_folder via JSON" do
    patch medical_folder_url(@medical_folder),
      params: { medical_folder: { name: "JSON Updated" } },
      as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "JSON Updated", json["name"]
  end

  test "should destroy medical_folder via JSON" do
    assert_difference("MedicalFolder.count", -1) do
      delete medical_folder_url(@medical_folder), as: :json
    end

    assert_response :no_content
  end

  # ============ Authorization Tests ============

  test "should not access other user's folder" do
    other_user = users(:two)
    other_folder = medical_folders(:two)

    # Verify the folder belongs to the other user
    assert_equal other_user.id, other_folder.user_id

    assert_raises(ActiveRecord::RecordNotFound) do
      get medical_folder_url(other_folder)
    end
  end
end
