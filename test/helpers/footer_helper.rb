module FooterHelper
  def footer_columns
    @footer_columns ||= FooterColumn.includes(:footer_links).to_a
  end

  def social_links
    @social_links ||= SocialLink.all.to_a
  end
end
