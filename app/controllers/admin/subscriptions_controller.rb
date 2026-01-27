module Admin
  class SubscriptionsController < BaseController
    before_action :set_user, only: %i[show edit update destroy]

    def index
      @users = User.includes(subscription: :plan).order(:email_address)
      @plans = Plan.active.order(:monthly_price)
    end

    def show
    end

    def edit
      @plans = Plan.active.order(:monthly_price)
      @subscription = @user.subscription || @user.build_subscription
    end

    def update
      @subscription = @user.subscription || @user.build_subscription

      if params[:subscription][:plan_id].blank?
        # Remove subscription (downgrade to free)
        @user.subscription&.destroy
        redirect_to admin_subscriptions_path, notice: t("admin.subscriptions.downgraded", user: @user.display_name)
      elsif @subscription.update(subscription_params)
        redirect_to admin_subscriptions_path, notice: t("admin.subscriptions.updated", user: @user.display_name)
      else
        @plans = Plan.active.order(:monthly_price)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @user.subscription&.destroy
      redirect_to admin_subscriptions_path, notice: t("admin.subscriptions.removed", user: @user.display_name), status: :see_other
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def subscription_params
      params.require(:subscription).permit(:plan_id, :billing_cycle, :status, :ends_at, :notes)
    end
  end
end
