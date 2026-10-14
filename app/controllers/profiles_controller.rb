class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def show
    ensure_user_code
    build_health
  end

  def update
    if @user.update(profile_params)
      redirect_to profile_path, status: :see_other, notice: "Profile updated."
    else
      build_health
      render :show, status: :unprocessable_entity
    end
  end

  def password
    if @user.update_with_password(password_params)
      bypass_sign_in(@user)
      redirect_to profile_path, status: :see_other, notice: "Password changed."
    else
      redirect_to profile_path, status: :see_other, alert: @user.errors.full_messages.to_sentence
    end
  end

  def destroy
    if @user.destroy
      sign_out(@user)
      redirect_to root_path, status: :see_other, notice: "Your account has been deleted."
    else
      redirect_to profile_path, status: :see_other, alert: "Could not delete your account."
    end
  rescue ActiveRecord::InvalidForeignKey
    redirect_to profile_path, status: :see_other,
                alert: "Remove your properties and inquiries first, then delete your account."
  end

  private

  def set_user
    @user = current_user
    @name_col = (%w[full_name name username] & User.column_names).first
    @photo    = (User.reflect_on_all_attachments.map { |a| a.name.to_s } &
                 %w[avatar profile_image profile_photo photo image picture]).first
  end

  def profile_params
    keys = [
      @name_col,
      :email,
      :phone,
      :company_name,
      :gstin,
      :address,
      :city,
      :state,
      :pincode,
      :bio,
      :avatar_url
    ]

    # Permit only existing database columns
    keys = keys.compact.select do |key|
      User.column_names.include?(key.to_s)
    end

    # Permit the actual Active Storage attachment, if configured
    keys << @photo.to_sym if @photo.present?

    attrs = params.require(:user).permit(*keys)

    attrs[:gstin] = attrs[:gstin].to_s.upcase.strip if attrs.key?(:gstin)

    attrs
  end
 
  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end

  def ensure_user_code
    return unless User.column_names.include?("user_code") && @user.user_code.blank?
    base = @user[@name_col].to_s.gsub(/[^A-Za-z]/, "").first(2).upcase.presence || "US"
    @user.update_column(:user_code, "#{base}#{(10_000 + @user.id * 37) % 90_000 + 10_000}")
  end

  def build_health
    checks = {
      "Name"    => @user[@name_col],
      "Mobile"  => @user.try(:phone),
      "Email"   => @user.email,
      "Company" => @user.try(:company_name),
      "Address" => @user.try(:address),
      "City"    => @user.try(:city),
      "State"   => @user.try(:state),
      "Pincode" => @user.try(:pincode)
    }
    missing = checks.select { |_, v| v.blank? }.keys
    done    = checks.size - missing.size
    @health = { done: done, missing: missing, pct: (done * 100.0 / checks.size).round }
  end
end
