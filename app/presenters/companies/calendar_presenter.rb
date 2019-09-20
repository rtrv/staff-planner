# frozen_string_literal: true

module Companies
  class CalendarPresenter
    attr_reader :company, :name, :id, :days, :working_days, :events, :holidays

    # rubocop: disable Metrics/AbcSize
    def initialize(company, params)
      @company = company
      @days = if params[:start_period].present? && params[:end_period].present?
                (params[:start_period].to_date)..(params[:end_period].to_date)
              else
                (Date.today)..(Date.today + 30)
              end
      @working_days = @company.working_days.pluck(:day_of_week)
      @events = Event.range(@days.first, @days.last).group_by(&:employee_id)
      @holidays = Holiday.where(date: days.first..days.last)
    end
    # rubocop: enable Metrics/AbcSize

    def employees
      @employees ||= company.employees.includes(:account)
    end

    def employee_events(employee)
      events[employee.id]
        .map { |event| (event.start_period.to_date)..(event.end_period.to_date) }
        .flat_map(&:to_a)
    end

    # rubocop: disable Metrics/AbcSize

    def days_status(employee)
      days.each_with_object({}) do |day, working_month|
        working_month[day] = working_days.include?(day.strftime('%w').to_i) ? 'work' : 'holiday'
        working_month[day] = 'state_holiday' if holidays.include?(day)
        working_month[day] = 'fullday_event' if
          events[employee.id].present? && employee_events(employee).include?(day.to_date)
        next unless working_month[day] == 'fullday_event'

        half_event(day, working_month)
      end
    end

    # rubocop: disable Metrics/MethodLength
    def half_event(day, working_month)
      events.each do |_employee, employee_events|
        employee_events.each do |event|
          if event.end_period.to_date.eql?(day) && event.end_period.hour == Event::HALF_DAY
            working_month[day] = 'first_half_of_day'
          elsif event.start_period.hour == Event::HALF_DAY &&
                event.end_period.hour == Event::END_DAY &&
                (event.end_period..event.start_period).include?(day)
            working_month[day] = 'second_half_of_day'
          end
        end
      end
    end
    # rubocop: enable Metrics/MethodLength
    # rubocop: enable Metrics/AbcSize
  end
end
