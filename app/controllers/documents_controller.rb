class DocumentsController < ApplicationController
  include PlanLimits

  before_action :set_medical_folder
  before_action :set_document, only: %i[show edit update destroy]

  def index
    @documents = @medical_folder.documents.recent.with_attached_file

    respond_to do |format|
      format.html
      format.json { render json: documents_json(@documents) }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: document_json(@document) }
    end
  end

  def new
    @document = @medical_folder.documents.build
  end

  def create
    # Check storage limit before creating
    if document_params[:file].present? && storage_limit_exceeded?(document_params[:file])
      respond_to do |format|
        format.html do
          @document = @medical_folder.documents.build(document_params)
          flash.now[:alert] = t("plan_limits.storage_exceeded", limit: current_user.storage_limit_mb)
          render :new, status: :unprocessable_entity
        end
        format.json do
          render json: { error: t("plan_limits.storage_exceeded", limit: current_user.storage_limit_mb) },
            status: :forbidden
        end
      end
      return
    end

    @document = @medical_folder.documents.build(document_params)

    respond_to do |format|
      if @document.save
        format.html { redirect_to medical_folder_path(@medical_folder), notice: t("flash.documents.created") }
        format.json { render json: document_json(@document), status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @document.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    # Check storage limit if file is being replaced
    if document_params[:file].present? && storage_limit_exceeded?(document_params[:file])
      respond_to do |format|
        format.html do
          flash.now[:alert] = t("plan_limits.storage_exceeded", limit: current_user.storage_limit_mb)
          render :edit, status: :unprocessable_entity
        end
        format.json do
          render json: { error: t("plan_limits.storage_exceeded", limit: current_user.storage_limit_mb) },
            status: :forbidden
        end
      end
      return
    end

    respond_to do |format|
      if @document.update(document_params)
        format.html { redirect_to medical_folder_document_path(@medical_folder, @document), notice: "Document updated successfully." }
        format.json { render json: document_json(@document) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @document.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @document.destroy

    respond_to do |format|
      format.html { redirect_to medical_folder_path(@medical_folder), notice: t("flash.documents.deleted"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_medical_folder
    @medical_folder = current_user.medical_folders.find(params[:medical_folder_id])
  end

  def set_document
    @document = @medical_folder.documents.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:title, :document_date, :notes, :file, :offline_id)
  end

  def document_json(doc)
    {
      id: doc.id,
      title: doc.title,
      document_date: doc.document_date&.iso8601,
      notes: doc.notes,
      file_type: doc.file_type,
      file_size_mb: doc.file_size_mb,
      file_url: doc.file.attached? ? url_for(doc.file) : nil,
      file_name: doc.file.attached? ? doc.file.filename.to_s : nil,
      medical_folder_id: doc.medical_folder_id,
      created_at: doc.created_at.iso8601,
      updated_at: doc.updated_at.iso8601
    }
  end

  def documents_json(documents)
    {
      documents: documents.map { |d| document_json(d) },
      medical_folder_id: @medical_folder.id,
      synced_at: Time.current.iso8601
    }
  end
end
