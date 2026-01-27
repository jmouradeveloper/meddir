class MedicalFoldersController < ApplicationController
  include PlanLimits

  before_action :set_medical_folder, only: %i[show edit update destroy]
  before_action :enforce_folder_limit!, only: %i[new create]

  def index
    @medical_folders = current_user.medical_folders.recent.includes(:documents)

    respond_to do |format|
      format.html
      format.json { render json: folders_json(@medical_folders) }
    end
  end

  def show
    @documents = @medical_folder.documents.recent.with_attached_file
    @shareable_links = @medical_folder.shareable_links.active

    respond_to do |format|
      format.html
      format.json { render json: folder_json(@medical_folder, include_documents: true) }
    end
  end

  def new
    @medical_folder = current_user.medical_folders.build
  end

  def create
    @medical_folder = current_user.medical_folders.build(medical_folder_params)

    respond_to do |format|
      if @medical_folder.save
        format.html { redirect_to @medical_folder, notice: t("flash.medical_folders.created") }
        format.json { render json: folder_json(@medical_folder), status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @medical_folder.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @medical_folder.update(medical_folder_params)
        format.html { redirect_to @medical_folder, notice: t("flash.medical_folders.updated") }
        format.json { render json: folder_json(@medical_folder) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @medical_folder.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @medical_folder.destroy

    respond_to do |format|
      format.html { redirect_to dashboard_path, notice: t("flash.medical_folders.deleted"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_medical_folder
    @medical_folder = current_user.medical_folders.find(params[:id])
  end

  def medical_folder_params
    params.require(:medical_folder).permit(:name, :specialty, :description, :offline_id)
  end

  def folder_json(folder, include_documents: false)
    data = {
      id: folder.id,
      name: folder.name,
      specialty: folder.specialty,
      specialty_name: folder.specialty_name,
      specialty_color: folder.specialty_color,
      description: folder.description,
      documents_count: folder.documents_count,
      created_at: folder.created_at.iso8601,
      updated_at: folder.updated_at.iso8601
    }

    if include_documents
      data[:documents] = folder.documents.recent.with_attached_file.map { |doc| document_json(doc) }
    end

    data
  end

  def folders_json(folders)
    {
      folders: folders.map { |f| folder_json(f) },
      synced_at: Time.current.iso8601
    }
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
      medical_folder_id: doc.medical_folder_id,
      created_at: doc.created_at.iso8601,
      updated_at: doc.updated_at.iso8601
    }
  end
end
