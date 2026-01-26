require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @medical_folder = medical_folders(:one)
    @document = documents(:one)
    sign_in_as(@user)
  end

  # ============ HTML Format Tests ============

  test "should get index" do
    get medical_folder_documents_url(@medical_folder)
    assert_response :success
  end

  test "should get new" do
    get new_medical_folder_document_url(@medical_folder)
    assert_response :success
  end

  test "should show document" do
    get medical_folder_document_url(@medical_folder, @document)
    assert_response :success
  end

  test "should get edit" do
    get edit_medical_folder_document_url(@medical_folder, @document)
    assert_response :success
  end

  test "should update document" do
    patch medical_folder_document_url(@medical_folder, @document), params: {
      document: { title: "Updated Title" }
    }
    assert_redirected_to medical_folder_document_url(@medical_folder, @document)
  end

  test "should destroy document" do
    assert_difference("Document.count", -1) do
      delete medical_folder_document_url(@medical_folder, @document)
    end

    assert_redirected_to medical_folder_url(@medical_folder)
  end

  # ============ JSON Format Tests (for PWA/Offline sync) ============

  test "should get index as JSON" do
    get medical_folder_documents_url(@medical_folder), as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json.key?("documents")
    assert json.key?("medical_folder_id")
    assert json.key?("synced_at")
    assert json["documents"].is_a?(Array)
    assert_equal @medical_folder.id, json["medical_folder_id"]
  end

  test "should show document as JSON" do
    get medical_folder_document_url(@medical_folder, @document), as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @document.id, json["id"]
    assert_equal @document.title, json["title"]
    assert_equal @medical_folder.id, json["medical_folder_id"]
    assert json.key?("document_date")
    assert json.key?("notes")
    assert json.key?("file_type")
    assert json.key?("created_at")
    assert json.key?("updated_at")
  end

  test "should update document via JSON" do
    patch medical_folder_document_url(@medical_folder, @document),
      params: { document: { title: "JSON Updated Title" } },
      as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "JSON Updated Title", json["title"]
  end

  test "should return errors when update fails via JSON" do
    patch medical_folder_document_url(@medical_folder, @document),
      params: { document: { title: "" } },
      as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json.key?("errors")
  end

  test "should destroy document via JSON" do
    assert_difference("Document.count", -1) do
      delete medical_folder_document_url(@medical_folder, @document), as: :json
    end

    assert_response :no_content
  end

  # ============ Authorization Tests ============

  test "should not access document in other user's folder" do
    other_user = users(:two)
    other_folder = medical_folders(:two)

    assert_raises(ActiveRecord::RecordNotFound) do
      get medical_folder_documents_url(other_folder)
    end
  end
end
