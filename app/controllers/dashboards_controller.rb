class DashboardsController < ApplicationController
  def show
    @medical_folders = current_user.medical_folders.recent.includes(:documents)
    @folders_by_specialty = @medical_folders.group_by(&:specialty)
    @total_documents = Document.joins(:medical_folder).where(medical_folders: { user_id: current_user.id }).count
    @recent_documents = Document.joins(:medical_folder)
                                .where(medical_folders: { user_id: current_user.id })
                                .recent
                                .limit(5)
                                .includes(file_attachment: :blob)
  end
end

