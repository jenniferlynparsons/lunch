module MAPI
  module Services
    module Rates
      module BlackoutDates
        SQL='SELECT BLACKOUT_DATE FROM WEB_ADM.AO_MATURITY_BLACKOUT_DATES'

        def self.blackout_dates(environment)
          environment == :production ? blackout_dates_production : blackout_dates_development
        end

        def self.blackout_dates_production
          begin
            dates = []
            date_cursor = ActiveRecord::Base.connection.execute(SQL)
            while date = date_cursor.fetch()
              dates += date
            end
            dates
          rescue => e
            warn(:blackout_dates_production, e.message)
          end
        end

        def self.fake_data_fixed
          JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'blackout_dates.json'))).map{ |d| Date.parse(d) }
        end

        def self.fake_data_relative_to_today
          [Time.zone.today + 1.week, Time.zone.today + 3.week, Time.zone.today + 1.year]
        end

        def self.blackout_dates_development
          fake_data_relative_to_today + fake_data_fixed
        end
      end
    end
  end
end