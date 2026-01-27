module PlanLimits
  extend ActiveSupport::Concern

  included do
    helper_method :upgrade_path if respond_to?(:helper_method)
  end

  private

  def enforce_folder_limit!
    return if current_user.can_create_folder?

    respond_to do |format|
      format.html do
        redirect_to upgrade_path,
          alert: t("plan_limits.folders_exceeded", limit: current_user.current_plan.folders_limit)
      end
      format.json do
        render json: { error: t("plan_limits.folders_exceeded", limit: current_user.current_plan.folders_limit) },
          status: :forbidden
      end
    end
  end

  def enforce_storage_limit!(file)
    return if file.nil?
    return if current_user.can_upload?(file.size)

    respond_to do |format|
      format.html do
        redirect_to upgrade_path,
          alert: t("plan_limits.storage_exceeded", limit: current_user.storage_limit_mb)
      end
      format.json do
        render json: { error: t("plan_limits.storage_exceeded", limit: current_user.storage_limit_mb) },
          status: :forbidden
      end
    end
  end

  def enforce_sharing_enabled!
    return if current_user.can_share?

    respond_to do |format|
      format.html do
        redirect_to upgrade_path,
          alert: t("plan_limits.sharing_disabled")
      end
      format.json do
        render json: { error: t("plan_limits.sharing_disabled") },
          status: :forbidden
      end
    end
  end

  def enforce_shareable_link_limit!
    return if current_user.can_create_shareable_link?

    respond_to do |format|
      format.html do
        redirect_to upgrade_path,
          alert: t("plan_limits.links_exceeded", limit: current_user.current_plan.active_links_limit)
      end
      format.json do
        render json: { error: t("plan_limits.links_exceeded", limit: current_user.current_plan.active_links_limit) },
          status: :forbidden
      end
    end
  end

  def upgrade_path
    subscriptions_path
  end

  def storage_limit_exceeded?(file)
    return false if file.nil?
    !current_user.can_upload?(file.size)
  end
end
