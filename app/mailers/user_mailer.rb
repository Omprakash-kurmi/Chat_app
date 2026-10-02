class UserMailer < ApplicationMailer
  def welcome(user)
    @user = user
    @rooms_url = rooms_url

    mail(to: @user.email, subject: "Welcome to Chat_App")
  end
end