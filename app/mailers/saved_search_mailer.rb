class SavedSearchMailer < ApplicationMailer
  def new_match(saved_search, property)
    @search   = saved_search
    @property = property
    mail(to: saved_search.user.email, subject: "New home matching “#{saved_search.name}”")
  end
end
