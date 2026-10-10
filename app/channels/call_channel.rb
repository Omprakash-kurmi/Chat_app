class CallChannel < ApplicationCable::Channel
  TYPES = %w[ring accept decline busy offer answer ice end].freeze

  def subscribed
    inquiry = Inquiry.find_by(id: params[:inquiry_id])
    return reject unless inquiry && participant?(inquiry)

    @inquiry = inquiry
    stream_from "inquiry_call_#{inquiry.id}"
  end

  def signal(data)
    return unless @inquiry && TYPES.include?(data["type"])

    ActionCable.server.broadcast(
      "inquiry_call_#{@inquiry.id}",
      {
        from: current_user.id,
        type: data["type"],
        media: data["media"],
        payload: data["payload"]
      }
    )
  end

  def log_call(data)
    return unless @inquiry

    status = data["status"]
    return unless %w[completed missed declined cancelled].include?(status)

    kind = data["media"] == "video" ? "Video" : "Voice"
    secs = data["seconds"].to_i.clamp(0, 86_400)
    body =
      case status
      when "completed" then "#{kind} call · #{call_duration(secs)}"
      when "missed"    then "Missed #{kind.downcase} call"
      when "declined"  then "#{kind} call declined"
      else                  "Cancelled #{kind.downcase} call"
      end

    @inquiry.messages.create(user: current_user, body: body, kind: "call")
  end

  private

  def participant?(inquiry)
    inquiry.user_id == current_user.id || inquiry.property.user_id == current_user.id
  end

  def call_duration(secs)
    return "#{secs}s" if secs < 60
    m, s = secs.divmod(60)
    m < 60 ? "#{m}m #{s}s" : "#{m / 60}h #{m % 60}m"
  end
end