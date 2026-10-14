module ApplicationHelper
  def safe_external_url(url)
    uri = URI.parse(url.to_s.strip)
    %w[http https].include?(uri.scheme) ? uri.to_s : "#"
  rescue URI::InvalidURIError
    "#"
  end
end
