class UserMailer < ApplicationMailer
  def welcome(user)
    @user = user
    @root_url = root_url

    mail(to: @user.email, subject: "Welcome to Chat_App")
  end
end
