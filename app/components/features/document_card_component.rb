# frozen_string_literal: true

module Features
  class DocumentCardComponent < ViewComponent::Base
    def initialize(document:, medical_folder:, size: :default)
      @document = document
      @medical_folder = medical_folder
      @size = size.to_sym
    end

    erb_template <<~ERB
      <%= link_to helpers.medical_folder_document_path(@medical_folder, @document), class: link_classes do %>
        <div class="<%= icon_container_classes %> rounded-lg bg-slate-700/50 flex items-center justify-center flex-shrink-0">
          <%= render Ui::IconComponent.new(name: file_icon, size: icon_size, color: file_color) %>
        </div>
        <div class="min-w-0 flex-1">
          <h3 class="text-white font-medium group-hover:text-emerald-400 transition-colors truncate"><%= @document.title %></h3>
          <div class="flex items-center gap-3 text-sm text-slate-500">
            <span><%= @document.formatted_date %></span>
            <% if @document.file.attached? %>
              <span>&bull;</span>
              <span><%= @document.file_size_mb %> MB</span>
            <% end %>
          </div>
        </div>
        <%= render Ui::IconComponent.new(name: :arrow_right, size: :md, color: "slate-500 group-hover:text-emerald-400 transition-colors") %>
      <% end %>
    ERB

    private

    def link_classes
      case @size
      when :compact
        "block bg-slate-800/30 hover:bg-slate-800/60 border border-slate-700/50 rounded-xl p-4 transition-all"
      else
        "group flex items-center gap-4 bg-slate-800/30 hover:bg-slate-800/60 border border-slate-700/50 rounded-xl p-4 transition-all"
      end
    end

    def icon_container_classes
      @size == :compact ? "w-10 h-10" : "w-12 h-12"
    end

    def icon_size
      @size == :compact ? :md : :lg
    end

    def file_icon
      @document.file_type == :pdf ? :document_pdf : :image
    end

    def file_color
      @document.file_type == :pdf ? "red-400" : "blue-400"
    end
  end
end
