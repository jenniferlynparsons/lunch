require 'date'
require 'savon'

module MAPI
  module Services
    module EtransactAdvances
      module ExecuteTrade

        LOAN_MAPPING = {
          whole: 'WHOLE LOAN',
          agency: 'SBC-AGENCY',
          aaa: 'SBC-AAA',
          aa: 'SBC-AA'
        }.with_indifferent_access

        def self.init_execute_trade_connection(environment)
          if environment == :production
            @@execute_trade_connection ||= Savon.client(
              wsdl: ENV['MAPI_TRADE_ENDPOINT'],
              env_namespace: :soapenv,
              namespaces: {'xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd', 'xmlns:v1' => 'http://fhlbsf.com/schema/msg/trade/v1', 'xmlns:v11' => 'http://fhlbsf.com/schema/canonical/common/v1', 'xmlns:v12' => 'http://fhlbsf.com/schema/canonical/trade/v1', 'xmlns:v13' => 'http://fhlbsf.com/schema/canonical/shared/v1', 'xmlns:v14' => 'http://fhlbsf.com/schema/canonical/advance/v1', 'xmlns:v15' => 'http://fhlbsf.com/schema/canonical/fixedIncome/v1', 'xmlns:v16' => 'http://fhlbsf.com/schema/canonical/swap/v1', 'xmlns:v17' => 'http://fhlbsf.com/schema/canonical/swaption/v1', 'xmlns:v18' => 'http://fhlbsf.com/schema/canonical/capfloor/v1', 'xmlns:v19' => 'http://fhlbsf.com/schema/canonical/moneyMarket/v1', 'xmlns:v110' => 'http://fhlbsf.com/schema/canonical/lc/v1', 'xmlns:v111' => 'http://fhlbsf.com/schema/canonical/simpleTransfer/v1'},
              element_form_default: :qualified,
              namespace_identifier: :v1,
              pretty_print_xml: true
            )
          else
            @@execute_trade_connection = nil
          end
        end

        def self.round_up_stock(current_stock)
          if current_stock > 0
            (current_stock % 100 == 0 ? current_stock : current_stock + 100 - (current_stock % 100)).to_i
          else
            0
          end
        end

        def self.round_down_stock(current_stock)
          (current_stock % 100 == 0 ? current_stock : current_stock + 100 - (current_stock % 100)).to_i
        end

        def self.get_signer_full_name(environment, signer)
          signer_connection_string = <<-SQL
            Select
             SIGNERS.FULLNAME
            From
             SIGNER.SIGNERS
            Left Join
             WEB_ADM.ETRANSACT_SIGNER
            On
             SIGNERS.SIGNERID = ETRANSACT_SIGNER.SIGNER_ID
            WHERE
             ETRANSACT_SIGNER.LOGIN_ID = #{ActiveRecord::Base.connection.quote(signer)}
          SQL
          if environment == :production
            signer_cursor = ActiveRecord::Base.connection.execute(signer_connection_string)
            while row = signer_cursor.fetch()
              signer_full_name = row[0]
              break
            end
            signer_full_name
          else
            'Test User'
          end
        end

        def self.get_maturity_date (settlement_date, term)
          maturity_date = settlement_date.to_date
          if (term == 'overnight') || (term == 'open')
            maturity_date = maturity_date + 1.day
          elsif term[1].upcase == 'W'
            maturity_date = maturity_date + (7*term[0].to_i).day
          elsif term[1].upcase == 'M'
            maturity_date = maturity_date + (term[0].to_i).month
          elsif term[1].upcase == 'Y'
            maturity_date = maturity_date + (term[0].to_i).year
          end
          maturity_date
        end

        def self.get_payment_info(term, collateral, settlement_date, maturity_date)
          # Advance payment frequency and payment day of the month
          advance_payment_day_of_month = 0
          if (term == 'overnight')
            @@payment_at = 'Overnight'
            advance_payment_frequency = {
              'v13:frequency' => 1,
              'v13:frequencyUnit' => 'T'
            }
          elsif (term == 'open')
            @@payment_at = 'End Of Month'
            advance_payment_frequency = {
              'v13:frequency' => 1,
              'v13:frequencyUnit' => 'M'
            }
            advance_payment_day_of_month = 31
          else
            if LOAN_MAPPING[collateral] == 'WHOLE LOAN'
              if ((settlement_date + 1.day).month == maturity_date.month) && ((settlement_date + 1.day).year == maturity_date.year)
                advance_payment_frequency = {
                  'v13:frequency' => 1,
                  'v13:frequencyUnit' => 'T'
                }
              else
                advance_payment_frequency = {
                  'v13:frequency' => 1,
                  'v13:frequencyUnit' => 'M'
                }
              end
              @@payment_at = 'Maturity'
            else
              if (maturity_date - settlement_date).to_i <= 180
                @@payment_at = 'Maturity'
                advance_payment_frequency = {
                  'v13:frequency' => 1,
                  'v13:frequencyUnit' => 'T'
                }
              else
                @@payment_at = 'Semiannual'
                advance_payment_frequency = {
                  'v13:frequency' => 6,
                  'v13:frequencyUnit' => 'M'
                }
              end
            end
          end
          {
            payment_at: @@payment_at,
            advance_payment_frequency: advance_payment_frequency,
            advance_payment_day_of_month: advance_payment_day_of_month
          }
        end

        def self.get_advance_rate_schedule(term, interest, day_count, settlement_date, maturity_date)
          # Advance Rate Schedule
          if (term == 'overnight') || (term == 'open')
            advance_rate_schedule = {
              'v13:initialRate' => interest,
              'v13:floatingRateSchedule' => {
                'v13:floatingPeriod' => {
                  'v13:startDate' => Date.today,
                  'v13:rateIndices' => {
                    'v13:rateIndex' => {
                      'v13:index' => '',
                      'v13:tenor' => {
                        'v13:frequency' => 1,
                        'v13:frequencyUnit' => 'D'
                      },
                      'v13:weight' => 1
                    }
                  },
                  'v13:periodicCap' => 100,
                  'v13:periodicFloor' => 0,
                  'v13:dayCountBasis' => day_count,
                  'v13:maximumRate' => 100,
                  'v13:minimumRate' => 0
                }
              },
              'v13:roundingConvention' => 'NEAREST'
            }
          else
            advance_rate_schedule = {
              'v13:initialRate' => interest,
              'v13:fixedRateSchedule' => {
                'v13:step' => {
                  'v13:startDate' => settlement_date,
                  'v13:endDate' => maturity_date,
                  'v13:rate' => interest,
                  'v13:dayCountBasis' => day_count
                }
              },
              'v13:roundingConvention' => 'NEAREST'
            }
          end
          advance_rate_schedule
        end

        def self.get_advance_product_info(term)
          # Product information and term frequency, which depends on the term type
          if (term == 'overnight') || (term == 'open')
            advance_product_info = {
              'v14:product' => term.gsub('overnight', 'O/N').upcase + ' VRC',
              'v14:subProduct' => 'VRC',
              'v14:term' => {
                'v13:frequency' => 1,
                'v13:frequencyUnit' => 'D'
              }
            }
          else
            advance_product_info = {
              'v14:product' => 'FX CONSTANT',
              'v14:subProduct' => 'FRC',
              'v14:term' => {
                'v13:frequency' => term[0].to_i,
                'v13:frequencyUnit' => term[1].upcase
              }
            }
          end
          advance_product_info
        end

        def self.build_message(member_id, instrument, operation, amount, advance_term, advance_type, rate, signer, markup, blended_cost_of_funds, cost_of_funds, benchmark_rate, maturity_date, settlement_date, day_count)
          # Advance lender info and amount of the loan
          advance_lender_amount = {
            'v14:lender' => 1133,
            'v14:borrower' => member_id,
            'v14:par' => {
              'v13:currency' => 'USD',
              'v13:amount' => amount
            }
          }

          # Advance payment, coupon and markup information
          # Markup, Blended Cost Of Funds To Libor, Cost Of Funds and Benchmark Rate will be calculated later
          payment_info = MAPI::Services::EtransactAdvances::ExecuteTrade::get_payment_info(advance_term, advance_type, settlement_date, maturity_date)
          advance_payment_coupon_markup = {
            'v14:maturityDate' => maturity_date,
            'v14:collateralType' => LOAN_MAPPING[advance_type],
            'v14:subsidyProgram' => 'N/A',
            'v14:prepaymentSymmetry' => false,
            'v14:prepaymentModelCode' => 1,
            'v14:coupon' => {
              'v13:paymentDates' => {
                'v13:firstPaymentDate' => Date.today,
                'v13:paymentFrequency' => payment_info[:advance_payment_frequency],
                'v13:paymentConvention' => {
                  'v13:businessDayAdjustment' => 'FOLLOWING',
                  'v13:businessDayCalendar' => 'USNY'
                },
                'v13:paymentDayOfMonth' =>  payment_info[:advance_payment_day_of_month]
              },
            },
            'v14:markup' => markup,
            'v14:blendedCostOfFundsToLibor' => blended_cost_of_funds,
            'v14:costOfFunds' => cost_of_funds,
            'v14:moneyStatus' => 'ROLL',
            'v14:benchmarkRate' => benchmark_rate
          }

          advance_payment_coupon_markup['v14:coupon'].deep_merge! MAPI::Services::EtransactAdvances::ExecuteTrade::get_advance_rate_schedule(advance_term, rate, day_count, settlement_date, maturity_date)
          # Header information and placeholders for the advances
          message = {
            'v11:caller' => [{'v11:id' => ENV['MAPI_WEB_AO_ACCOUNT']}],
            'v1:operationType' => operation,
            'v1:trade' => {
              'v12:tradeHeader' => {
                'v12:tradeId' => 1133,
                'v12:parties' => {
                  'v12:party' => [{
                    'v13:partyId' => 1133,
                    'v13:partyName' => 'FHLBank San Francisco',
                    'v12:trader' => ENV['MAPI_WEB_AO_ACCOUNT']
                   },
                   {'v13:partyId' => member_id}]
                },
                'v12:instrument' => instrument,
                'v12:tradeDate' => Date.today,
                'v12:settlementDate' => Date.today,
                'v12:openDateMaturity' => advance_term == 'open'
              },
              'v12:advance' => {},
            },
            'v1:arrayOfSigners' => [{'v1:signer' => signer}]
          }

          # Put it all together
          message['v1:trade']['v12:advance'].deep_merge! advance_lender_amount
          message['v1:trade']['v12:advance'].deep_merge! MAPI::Services::EtransactAdvances::ExecuteTrade::get_advance_product_info(advance_term)
          message['v1:trade']['v12:advance'].deep_merge! advance_payment_coupon_markup
          message
        end

        def self.execute_trade(app, member_id, instrument, operation, amount, advance_term, advance_type, rate, check_capstock, signer, markup, blended_cost_of_funds, cost_of_funds, benchmark_rate)
          data = if MAPI::Services::EtransactAdvances::ExecuteTrade::init_execute_trade_connection(app.settings.environment)
            member_id = member_id.to_i
            # Calculated values
            # True maturity date will be calculated later
            maturity_date = MAPI::Services::EtransactAdvances::ExecuteTrade::get_maturity_date(Date.today, advance_term)
            settlement_date = Date.today
            day_count = (LOAN_MAPPING[advance_type] == 'WHOLE LOAN') ? 'ACT/360' : 'ACT/ACT'

            # Check to see if advance would exceed the total advance amount allowed per day
            if MAPI::Services::EtransactAdvances::ExecuteTrade::advance_exceeds_total_daily_limit(app, amount)
              return {status: ['ExceedsTotalDailyLimitError']}.to_json
            end

            message = MAPI::Services::EtransactAdvances::ExecuteTrade::build_message(member_id, instrument, operation, amount, advance_term, advance_type, rate, signer, markup, blended_cost_of_funds, cost_of_funds, benchmark_rate, maturity_date, settlement_date, day_count)
            begin
              response = @@execute_trade_connection.call(:execute_trade, message_tag: 'executeTradeRequest', message: message, :soap_header => {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}})
            rescue Savon::Error => error
              raise error
            end

            if response.success?
              response.doc.remove_namespaces!
              fhlbsfresponse = response.doc.xpath('//Envelope//Body//executeTradeResponse')
              if fhlbsfresponse.at_css('transactionResult').content == 'Error'
                response_hash = {
                  'status' => [fhlbsfresponse.at_css('transactionResult').content],
                  'confirmation_number' => '',
                  'advance_rate' => '',
                  'advance_amount' => '',
                  'advance_term' => '',
                  'advance_type' => '',
                  'interest_day_count' => '',
                  'payment_on' => '',
                  'funding_date' => '',
                  'maturity_date' => '',
                }
              else
                response_hash = {}
                response_hash = MAPI::Services::EtransactAdvances::ExecuteTrade::check_capital_stock(fhlbsfresponse, response, response_hash) if check_capstock
                response_hash = MAPI::Services::EtransactAdvances::ExecuteTrade::check_credit(fhlbsfresponse, response, response_hash)
                response_hash = MAPI::Services::EtransactAdvances::ExecuteTrade::check_collateral(fhlbsfresponse, response, response_hash)

                # passed all checks
                if response_hash.blank?
                  response_hash = {
                    'status' => [fhlbsfresponse.at_css('transactionResult').content],
                    'confirmation_number' => (operation == 'EXECUTE')? fhlbsfresponse.at_css('trade tradeHeader tradeId').content : '',
                    'advance_rate' => rate.to_f,
                    'advance_amount' => amount.to_i,
                    'advance_term' => advance_term,
                    'advance_type' => LOAN_MAPPING[advance_type],
                    'interest_day_count' => day_count,
                    'payment_on' => @@payment_at,
                    'funding_date' => settlement_date,
                    'maturity_date' => maturity_date,
                  }
                end
              end
              response_hash
            end
          else
            if operation == 'EXECUTE'
              JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'quick_advance_confirmation.json')))
            else
              if (amount.to_i == 100001)
                 JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'quick_advance_credit_error.json')))
              elsif (amount.to_i == 100002)
                JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'quick_advance_collateral_error.json')))
              elsif (amount.to_i == 100003)
                JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'quick_advance_exceeds_total_daily_limit_error.json')))
              elsif (amount.to_i < 1000000) || (!check_capstock)
                JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'quick_advance_preview.json')))
              elsif amount.to_i < 2000000
                JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'quick_advance_capstock_preview.json')))
              elsif amount.to_i < 3000000
                JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'quick_advance_capstock_missing_gross.json')))
              else
                JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'quick_advance_capstock_missing_exception.json')))
              end
            end
          end
          data.to_json
        end

        def self.check_capital_stock(fhlbsfresponse, response, hash)
          new_hash = {}
          if (fhlbsfresponse.at_css('advanceValidation capitalStockValidations capitalStockValid') && fhlbsfresponse.at_css('advanceValidation capitalStockValidations capitalStockValid').content != 'true')
            capitalstockexceptions = response.doc.xpath('//Envelope//Body//executeTradeResponse//advanceValidation//capitalStockValidations')

            if !capitalstockexceptions.at_css('exception GrossUp')
              status = 'GrossUpError'
            elsif !capitalstockexceptions.at_css('exception')
              status = 'ExceptionError'
            else
              status = 'CapitalStockError'
            end
            # current stock calculations
            cumulative_stock_required = MAPI::Services::EtransactAdvances::ExecuteTrade::round_up_stock(capitalstockexceptions.at_css('exception cumulativeStockRequired') ? capitalstockexceptions.at_css('exception cumulativeStockRequired').content.to_i : 0)
            current_trade_stock_required = capitalstockexceptions.at_css('exception currentTradeStockRequired') ? capitalstockexceptions.at_css('exception currentTradeStockRequired').content.to_i : 0
            pre_trade_stock_required = MAPI::Services::EtransactAdvances::ExecuteTrade::round_down_stock(capitalstockexceptions.at_css('exception preTradeStockRequired') ? capitalstockexceptions.at_css('exception preTradeStockRequired').content.to_i : 0)
            if pre_trade_stock_required > 0
              net_stock_required = cumulative_stock_required
            else
              net_stock_required = cumulative_stock_required + pre_trade_stock_required
            end
            # gross up stock calculations
            gross_cumulative_stock_required = MAPI::Services::EtransactAdvances::ExecuteTrade::round_up_stock(capitalstockexceptions.at_css('exception GrossUp cumulativeStockRequired') ? capitalstockexceptions.at_css('exception GrossUp cumulativeStockRequired').content.to_i : 0)
            gross_current_trade_stock_required = capitalstockexceptions.at_css('exception GrossUp currentTradeStockRequired') ? capitalstockexceptions.at_css('exception GrossUp currentTradeStockRequired').content.to_i : 0
            gross_pre_trade_stock_required = MAPI::Services::EtransactAdvances::ExecuteTrade::round_down_stock(capitalstockexceptions.at_css('exception GrossUp preTradeStockRequired') ? capitalstockexceptions.at_css('exception GrossUp preTradeStockRequired').content.to_i : 0)
            if gross_pre_trade_stock_required > 0
              gross_net_stock_required = gross_cumulative_stock_required
            else
              gross_net_stock_required = gross_cumulative_stock_required + gross_pre_trade_stock_required
            end

            new_hash = {
              'status' => [status],
              'authorized_amount' => capitalstockexceptions.at_css('authorizedAmount') ? capitalstockexceptions.at_css('authorizedAmount').content.to_i : 0,
              'exception_message' => capitalstockexceptions.at_css('exception exceptionMessage') ? capitalstockexceptions.at_css('exception exceptionMessage').content : '',
              'cumulative_stock_required' => cumulative_stock_required,
              'current_trade_stock_required' => current_trade_stock_required,
              'pre_trade_stock_required' => pre_trade_stock_required,
              'net_stock_required' => net_stock_required,
              'gross_amount' => capitalstockexceptions.at_css('exception GrossUp grossAmount') ? capitalstockexceptions.at_css('exception GrossUp grossAmount').content.to_i : 0,
              'gross_cumulative_stock_required' => gross_cumulative_stock_required,
              'gross_current_trade_stock_required' => gross_current_trade_stock_required,
              'gross_pre_trade_stock_required' => gross_pre_trade_stock_required,
              'gross_net_stock_required' => gross_net_stock_required
            }
          end
          hash.merge(new_hash){|key, old, new| old + new }
        end

        def self.check_credit(fhlbsfresponse, response, hash)
          new_hash = {}
          if (fhlbsfresponse.at_css('advanceValidation creditValidations creditValid') && fhlbsfresponse.at_css('advanceValidation creditValidations creditValid').content != 'true')
            credit_exception = response.doc.xpath('//Envelope//Body//executeTradeResponse//advanceValidation//creditValidations//creditValid')
            new_hash = {
              'status' => ['CreditError'],
              'credit_max_amount' => (credit_exception.at_css('maxAmount').content if credit_exception.at_css('maxAmount'))
            }
          end
          hash.merge(new_hash){|key, old, new| old + new }
        end

        def self.check_collateral(fhlbsfresponse, response, hash)
          new_hash = {}
          if (fhlbsfresponse.at_css('advanceValidation collateralValidations collateralValid') && fhlbsfresponse.at_css('advanceValidation collateralValidations collateralValid').content != 'true')
            collateral_exception = response.doc.xpath('//Envelope//Body//executeTradeResponse//advanceValidation//collateralValidations//collateralValid')
            new_hash = {
              'status' => ['CollateralError'],
              'collateral_max_amount' => (collateral_exception.at_css('maxAmount').content if collateral_exception.at_css('maxAmount')),
              'collateral_authorized_amount' => (collateral_exception.at_css('authorizedAmount').content if collateral_exception.at_css('authorizedAmount'))
            }
          end
          hash.merge(new_hash){|key, old, new| old + new }
        end

        def self.advance_exceeds_total_daily_limit(app, advance_amount)
          exceeds_limit = false
          if app.settings.environment == :production
            total_daily_limit_query = <<-SQL
            SELECT SETTING_VALUE
            FROM WEB_ADM.AO_SETTINGS
            WHERE SETTING_NAME = 'ShareholderTotalDailyLimit'
            SQL

            total_daily_limit = ActiveRecord::Base.connection.execute(total_daily_limit_query).fetch.try(&:first)
            current_daily_total = MAPI::Services::Member::TradeActivity.current_daily_total(app, 'ADVANCE')

            if (current_daily_total.to_f + advance_amount.to_f) > total_daily_limit.to_f
              exceeds_limit = true
            end
          end
          exceeds_limit
        end
      end
    end
  end
end