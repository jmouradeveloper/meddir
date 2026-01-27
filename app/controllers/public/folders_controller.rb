module Public
  class FoldersController < ApplicationController
    allow_unauthenticated_access

    def show
      @shareable_link = ShareableLink.find_by(token: params[:token])

      if @shareable_link.nil?
        render :not_found, status: :not_found
        return
      end

      unless @shareable_link.valid_for_access?
        if @shareable_link.access_limit_reached?
          render :access_limit_reached, status: :gone
        else
          render :expired, status: :gone
        end
        return
      end

      # Increment access count
      @shareable_link.increment_access!

      @medical_folder = @shareable_link.medical_folder
      @documents = @medical_folder.documents.recent.with_attached_file
      @owner = @medical_folder.user
    end
  end
end
