module DatePickerHelper

  def default_dates_hash
    today = Time.zone.now.to_date
    {
      this_month_start: today.beginning_of_month,
      today: today,
      last_month_start: today.beginning_of_month - 1.month,
      last_month_end: (today.beginning_of_month - 1.month).end_of_month,
      this_year_start: today.beginning_of_year,
      last_year_start: (today - 1.year).beginning_of_year,
      last_year_end: (today - 1.year).end_of_year
    }
  end

  def date_picker_presets(custom_start_date, custom_end_date = nil, custom_presets = nil )
    default_dates = default_dates_hash
    picker_presets = if custom_presets
                       [
                           {
                               label: custom_presets[:first_preset][:label],
                               start_date: custom_presets[:first_preset][:start_date],
                               end_date: custom_presets[:first_preset][:end_date]
                           },
                           {
                               label: custom_presets[:second_preset][:label],
                               start_date: custom_presets[:second_preset][:start_date],
                               end_date: custom_presets[:second_preset][:end_date]
                           },
                           {
                               label: t('datepicker.range.custom'),
                               start_date: custom_start_date,
                               end_date: custom_end_date,
                               is_custom: true
                           }
                       ]
                     else
                       [
                           {
                               label: t('datepicker.range.this_month', month: default_dates[:this_month_start].to_date.strftime('%B')),
                               start_date: default_dates[:this_month_start],
                               end_date: default_dates[:today]
                           },
                           {
                               label: default_dates[:last_month_start].to_date.strftime('%B'),
                               start_date: default_dates[:last_month_start],
                               end_date: default_dates[:last_month_end]
                           },
                           {
                               label: t('datepicker.range.custom'),
                               start_date: custom_start_date,
                               end_date: custom_end_date,
                               is_custom: true
                           }
                       ]
                     end


    if custom_end_date.nil?
      picker_presets.first[:label] = "#{t('global.as_of')} #{t('global.today')}"
      picker_presets.first[:start_date] = default_dates[:today]
      picker_presets[1][:label] = "#{t('global.as_of')} #{default_dates[:last_month_end].to_date.strftime('%B')} #{default_dates[:last_month_end].day.ordinalize}"
      picker_presets[1][:start_date] = default_dates[:last_month_end]
      picker_presets.last[:label] = t('datepicker.single.custom')
      picker_presets.last[:end_date] = custom_start_date
    end

    picker_presets.each do |preset|
      if preset[:start_date] == custom_start_date && (preset[:end_date] == custom_end_date || custom_end_date.nil?)
        preset[:is_default] = true
        break
      end
    end
    picker_presets
  end

end
