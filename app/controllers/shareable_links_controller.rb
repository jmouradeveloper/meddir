class ShareableLinksController < ApplicationController
  before_action :set_medical_folder

  def create
    expires_in = params[:expires_in] || "7_days"
    expires_at = ShareableLink::EXPIRATION_OPTIONS[expires_in]

    @shareable_link = @medical_folder.shareable_links.build(
      expires_at: expires_at.present? ? Time.current + expires_at : nil
    )

    if @shareable_link.save
      redirect_to @medical_folder, notice: "Share link created successfully."
    else
      redirect_to @medical_folder, alert: "Could not create share link."
    end
  end

  def destroy
    @shareable_link = @medical_folder.shareable_links.find(params[:id])
    @shareable_link.update(active: false)
    redirect_to @medical_folder, notice: "Share link revoked.", status: :see_other
  end

  private

  def set_medical_folder
    @medical_folder = current_user.medical_folders.find(params[:medical_folder_id])
  end
end

