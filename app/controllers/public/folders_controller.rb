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
        render :expired, status: :gone
        return
      end

      @medical_folder = @shareable_link.medical_folder
      @documents = @medical_folder.documents.recent.with_attached_file
      @owner = @medical_folder.user
    end
  end
end

