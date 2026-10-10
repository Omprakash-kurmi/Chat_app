module EventCalendarHelper
  # Works with whatever column names your Event table uses.
  def evc_title(event)
    event.try(:title).presence || event.try(:name).presence || "Event"
  end

  def evc_time(event)
    event.try(:starts_at) || event.try(:start_time) || event.try(:start_at) ||
      event.try(:event_date) || event.try(:scheduled_at) || event.try(:date)
  end

  def evc_date(event)
    evc_time(event)&.to_date
  end

  def evc_clock(event)
    t = evc_time(event)
    t.respond_to?(:hour) ? t.strftime("%l:%M %p").strip : nil
  end
end