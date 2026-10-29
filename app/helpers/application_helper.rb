module ApplicationHelper
  def safe_external_url(url)
    uri = URI.parse(url.to_s.strip)
    %w[http https].include?(uri.scheme) ? uri.to_s : "#"
  rescue URI::InvalidURIError
    "#"
  end
    # Name shown everywhere: profile name first, then username, then email
  def display_name(user)
    return "Guest" if user.blank?
    user.try(:name).presence || user.try(:username).presence || user.email.to_s.split("@").first
  end

  # Profile photo if there is one, otherwise a coloured circle with the initial
  def user_avatar(user, size: 36, extra_class: "")
    style = "width:#{size}px;height:#{size}px;border-radius:50%;flex:none;"
    if user.respond_to?(:avatar) && user.avatar.attached?
      image_tag url_for(user.avatar), alt: display_name(user), class: "uav #{extra_class}",
                style: style + "object-fit:cover;display:block;"
    else
      content_tag :span, display_name(user).first.to_s.upcase, class: "uav #{extra_class}",
        style: style + "display:inline-grid;place-items:center;color:#fff;font-weight:700;" \
                       "font-size:#{(size * 0.42).round}px;background:linear-gradient(135deg,#ff5a8a,#ff2d55);"
    end
  end
end
