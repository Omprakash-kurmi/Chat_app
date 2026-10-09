module ReviewsHelper
  def rating_stars(rate, size: nil)
    content_tag :span, "", class: "rvx-stars", style: "--rate:#{rate.to_f};#{"font-size:#{size}px;" if size}",
                title: "#{rate} out of 5", "aria-label": "#{rate} out of 5 stars"
  end
end