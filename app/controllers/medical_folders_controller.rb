class MedicalFoldersController < ApplicationController
  before_action :set_medical_folder, only: %i[show edit update destroy]

  def index
    @medical_folders = current_user.medical_folders.recent.includes(:documents)
  end

  def show
    @documents = @medical_folder.documents.recent.with_attached_file
    @shareable_links = @medical_folder.shareable_links.active
  end

  def new
    @medical_folder = current_user.medical_folders.build
  end

  def create
    @medical_folder = current_user.medical_folders.build(medical_folder_params)

    if @medical_folder.save
      redirect_to @medical_folder, notice: "Folder created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @medical_folder.update(medical_folder_params)
      redirect_to @medical_folder, notice: "Folder updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @medical_folder.destroy
    redirect_to dashboard_path, notice: "Folder deleted successfully.", status: :see_other
  end

  private

  def set_medical_folder
    @medical_folder = current_user.medical_folders.find(params[:id])
  end

  def medical_folder_params
    params.require(:medical_folder).permit(:name, :specialty, :description)
  end
end

