class ShareableLinksController < ApplicationController
  include PlanLimits

  before_action :set_medical_folder
  before_action :enforce_sharing_enabled!, only: :create
  before_action :enforce_shareable_link_limit!, only: :create

  def create
    expires_in = params[:expires_in] || "7_days"
    expires_at = ShareableLink::EXPIRATION_OPTIONS[expires_in]

    @shareable_link = @medical_folder.shareable_links.build(
      expires_at: expires_at.present? ? Time.current + expires_at : nil
    )

    if @shareable_link.save
      redirect_to @medical_folder, notice: t("flash.shareable_links.created")
    else
      redirect_to @medical_folder, alert: t("flash.shareable_links.create_error")
    end
  end

  def destroy
    @shareable_link = @medical_folder.shareable_links.find(params[:id])
    @shareable_link.update(active: false)
    redirect_to @medical_folder, notice: t("flash.shareable_links.revoked"), status: :see_other
  end

  private

  def set_medical_folder
    @medical_folder = current_user.medical_folders.find(params[:medical_folder_id])
  end
end
