class AiAssistantsController < ApplicationController
  before_action :authenticate_user!

  def create
    message = params[:message].to_s.strip.first(500)
    return render(json: { reply: "Please type what you are looking for.", properties: [] }) if message.blank?

    history = Array(params[:history]).first(6).filter_map do |h|
      next unless h.respond_to?(:[])
      role = h[:role].to_s
      next unless %w[user assistant].include?(role)
      { role: role, text: h[:text].to_s.first(500) }
    end

    result = AiPropertyAssistant.new(message, history: history).call

    render json: {
      reply: result[:reply],
      properties: result[:properties].map do |p|
        {
          title: helpers.pg_title(p),
          price: helpers.cmp_price_label(p) || "Price on request",
          place: helpers.cmp_place(p),
          kind:  p.listing_type.to_s,
          url:   property_path(p)
        }
      end
    }
  end
end
