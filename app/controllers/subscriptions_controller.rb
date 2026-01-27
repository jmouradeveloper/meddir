class SubscriptionsController < ApplicationController
  def index
    @plans = Plan.active.order(:monthly_price)
    @current_plan = current_user.current_plan
    @subscription = current_user.subscription
  end

  def show
    @plan = current_user.current_plan
    @subscription = current_user.subscription
  end
end
