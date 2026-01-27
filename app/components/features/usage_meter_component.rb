# frozen_string_literal: true

module Features
  class UsageMeterComponent < ViewComponent::Base
    def initialize(user:, compact: false)
      @user = user
      @compact = compact
    end

    erb_template <<~ERB
      <div class="<%= @compact ? "space-y-2" : "space-y-4" %>">
        <%# Storage Usage %>
        <div>
          <div class="flex items-center justify-between mb-1">
            <span class="text-slate-400 text-sm"><%= I18n.t("components.usage_meter.storage") %></span>
            <span class="<%= storage_warning? ? "text-amber-400" : "text-slate-300" %> text-sm font-medium">
              <%= storage_used %> MB
              <% unless unlimited_storage? %>
                / <%= storage_limit %> MB
              <% end %>
            </span>
          </div>
          <% unless unlimited_storage? %>
            <div class="w-full bg-slate-700 rounded-full h-1.5">
              <div class="<%= storage_warning? ? "bg-amber-500" : "bg-gradient-to-r from-emerald-500 to-teal-500" %> h-1.5 rounded-full transition-all"
                   style="width: <%= storage_percentage %>%"></div>
            </div>
          <% else %>
            <div class="text-xs text-emerald-400"><%= I18n.t("components.usage_meter.unlimited") %></div>
          <% end %>
        </div>

        <%# Folders Usage %>
        <div>
          <div class="flex items-center justify-between mb-1">
            <span class="text-slate-400 text-sm"><%= I18n.t("components.usage_meter.folders") %></span>
            <span class="<%= folders_warning? ? "text-amber-400" : "text-slate-300" %> text-sm font-medium">
              <%= folders_count %>
              <% unless unlimited_folders? %>
                / <%= folders_limit %>
              <% end %>
            </span>
          </div>
          <% unless unlimited_folders? %>
            <div class="w-full bg-slate-700 rounded-full h-1.5">
              <div class="<%= folders_warning? ? "bg-amber-500" : "bg-gradient-to-r from-emerald-500 to-teal-500" %> h-1.5 rounded-full transition-all"
                   style="width: <%= folders_percentage %>%"></div>
            </div>
          <% else %>
            <div class="text-xs text-emerald-400"><%= I18n.t("components.usage_meter.unlimited") %></div>
          <% end %>
        </div>

        <% unless @compact %>
          <div class="pt-2 border-t border-slate-700">
            <%= link_to I18n.t("components.usage_meter.view_plans"), helpers.subscriptions_path, 
                class: "text-sm text-emerald-400 hover:text-emerald-300 transition-colors" %>
          </div>
        <% end %>
      </div>
    ERB

    private

    attr_reader :user

    def plan
      @plan ||= user.current_plan
    end

    def storage_used
      user.storage_used_mb
    end

    def storage_limit
      user.storage_limit_mb
    end

    def storage_percentage
      user.storage_percentage
    end

    def folders_count
      user.folders_count
    end

    def folders_limit
      user.folders_limit
    end

    def folders_percentage
      user.folders_percentage
    end

    def unlimited_storage?
      plan.unlimited_storage?
    end

    def unlimited_folders?
      plan.unlimited_folders?
    end

    def storage_warning?
      !unlimited_storage? && storage_percentage >= 80
    end

    def folders_warning?
      !unlimited_folders? && folders_percentage >= 80
    end
  end
end
