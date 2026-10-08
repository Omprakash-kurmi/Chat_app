class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    user = User.from_omniauth(request.env["omniauth.auth"])

    if user.persisted?
      flash[:notice] = "Signed in with Google."
      sign_in_and_redirect user, event: :authentication
    else
      redirect_to new_user_registration_path,
                  alert: "Couldn't sign you in with Google: #{user.errors.full_messages.to_sentence}"
    end
  end

  def failure
    redirect_to new_user_session_path, alert: "Google sign-in was cancelled or failed. Please try again."
  end
end
