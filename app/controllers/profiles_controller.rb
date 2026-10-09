class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def show; end

  def edit; end

  def update
    if @user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
    # accounts created before roles were enforced have no role: make them customers
    @user.update_column(:role, :customer) if @user.role.blank?
  end

  # Google accounts keep the email Google gave us
  def profile_params
    permitted = %i[name bio avatar]
    permitted << :email if @user.provider.blank?
    params.require(:user).permit(*permitted)
  end
end
