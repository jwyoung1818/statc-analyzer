module JournalsHelper
  def fancy_journal_time(time)
    if @time_now > time + 1.day
      time.strftime(t('date_format_time'))
    else
      distance_of_time_in_words(time, Time.zone.now) + " ago"
    end
  end
end
