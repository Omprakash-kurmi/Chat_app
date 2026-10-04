class PagesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def show
    @page = Page.find_by!(slug: params[:slug])
  end

  def home
    # if user_signed_in?
    #   redirect_to rooms_path
    # else
    #   redirect_to new_user_registration_path
    # end
  end
end
