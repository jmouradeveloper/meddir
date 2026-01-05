class DocumentsController < ApplicationController
  before_action :set_medical_folder
  before_action :set_document, only: %i[show edit update destroy]

  def index
    @documents = @medical_folder.documents.recent.with_attached_file
  end

  def show
  end

  def new
    @document = @medical_folder.documents.build
  end

  def create
    @document = @medical_folder.documents.build(document_params)

    if @document.save
      redirect_to medical_folder_path(@medical_folder), notice: "Document uploaded successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @document.update(document_params)
      redirect_to medical_folder_document_path(@medical_folder, @document), notice: "Document updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @document.destroy
    redirect_to medical_folder_path(@medical_folder), notice: "Document deleted successfully.", status: :see_other
  end

  private

  def set_medical_folder
    @medical_folder = current_user.medical_folders.find(params[:medical_folder_id])
  end

  def set_document
    @document = @medical_folder.documents.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:title, :document_date, :notes, :file)
  end
end

