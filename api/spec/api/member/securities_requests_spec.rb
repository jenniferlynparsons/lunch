require 'spec_helper'

describe MAPI::ServiceApp do
  include MAPI::Shared::Utils
  describe 'Securities Requests' do
    securities_request_module = MAPI::Services::Member::SecuritiesRequests
    describe 'GET `/securities/requests`' do
      let(:response) { double('response', to_json: nil) }
      let(:call_endpoint) { get "/member/#{member_id}/securities/requests"}
      before do
        allow(securities_request_module).to receive(:requests).and_return(response)
      end

      it 'calls `MAPI::Services::Member::SecuritiesRequests.requests` with an instance of the MAPI::Service app' do
        expect(securities_request_module).to receive(:requests).with(an_instance_of(MAPI::ServiceApp), any_args)
        call_endpoint
      end
      it 'calls `MAPI::Services::Member::SecuritiesRequests.requests` with the `member_id` param' do
        expect(securities_request_module).to receive(:requests).with(anything, member_id, any_args)
        call_endpoint
      end
      [:authorized, :awaiting_authorization].each do |status|
        mapped_status = MAPI::Services::Member::SecuritiesRequests::REQUEST_STATUS_MAPPING[status]
        it "calls `MAPI::Services::Member::SecuritiesRequests.requests` with `#{mapped_status}` if `#{status}` is passed as the status param" do
          expect(securities_request_module).to receive(:requests).with(anything, anything, mapped_status, any_args)
          get "/member/#{member_id}/securities/requests", status: status
        end
      end
      it 'calls `MAPI::Services::Member::SecuritiesRequests.requests` with `nil` for status if no status is passed' do
        expect(securities_request_module).to receive(:requests).with(anything, anything, nil, any_args)
        call_endpoint
      end
      it 'calls `MAPI::Services::Member::SecuritiesRequests.requests` with `nil` for status if the status param is not `:authorized` or `:awaiting_authorization`' do
        expect(securities_request_module).to receive(:requests).with(anything, anything, nil, any_args)
        get "/member/#{member_id}/securities/requests", status: SecureRandom.hex
      end
      it 'calls `MAPI::Services::Member::SecuritiesRequests.requests` with a range from a hundred years ago to today if no date params are passed' do
        end_date = Time.zone.today
        start_date = (end_date - 100.years)
        expect(securities_request_module).to receive(:requests).with(anything, anything, anything, (start_date..end_date))
        call_endpoint
      end
      it 'calls `MAPI::Services::Member::SecuritiesRequests.requests` with a range calculated from the date params' do
        end_date = (Time.zone.today - rand(10..20).days)
        start_date = (end_date - rand(1..25).years)
        expect(securities_request_module).to receive(:requests).with(anything, anything, anything, (start_date..end_date))
        get "/member/#{member_id}/securities/requests", settle_start_date: start_date, settle_end_date: end_date
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.requests`' do
      let(:app) { double(MAPI::ServiceApp, logger: double('logger')) }
      let(:call_method) { MAPI::Services::Member::SecuritiesRequests.requests(app, member_id) }

      describe 'when using fake data' do
        names = fake('securities_release_request_details')['names']
        let(:rng) { instance_double(Random) }
        let(:status_offset) { rand(0..1) }
        let(:submit_offset) { rand(0..4) }
        let(:authorized_offset) { rand(0..2) }
        let(:request_id) { rand(100000..999999) }
        let(:form_type) { rand(70..73) }
        let(:submitted_date) { Time.zone.today - submit_offset.days }
        let(:authorized_date) { submitted_date + authorized_offset.days }
        let(:submitted_by_offset) { rand(0..names.length-1) }
        let(:authorized_by_offset) { rand(0..names.length-1) }
        before do
          allow(securities_request_module).to receive(:should_fake?).and_return(true)
          allow(Random).to receive(:new).and_return(rng)
          allow(rng).to receive(:rand).and_return(1, request_id, status_offset)
        end

        it 'constructs a list of request objects' do
          n = rand(1..7)
          allow(rng).to receive(:rand).with(1..7).and_return(n)
          expect(call_method.length).to eq(n)
        end
        it 'passes the `request_id` to the `fake_header_details` method' do
          expect(securities_request_module).to receive(:fake_header_details).with(request_id, any_args).and_return({})
          call_method
        end
        it 'passes the `end_date` to the `fake_header_details` method' do
          expect(securities_request_module).to receive(:fake_header_details).with(request_id, Time.zone.today, any_args).and_return({})
          call_method
        end
        it 'passes the `status` to the `fake_header_details` method' do
          expect(securities_request_module).to receive(:fake_header_details).with(anything, anything, securities_request_module::MAPIRequestStatus::AUTHORIZED[status_offset]).and_return({})
          call_method
        end
      end
      describe 'when using real data' do
        let(:request_query) { double('request query') }
        before do
          allow(securities_request_module).to receive(:should_fake?).and_return(false)
          allow(securities_request_module).to receive(:requests_query).and_return(request_query)
          allow(securities_request_module).to receive(:fetch_hashes).and_return([])
        end
        it 'calls `fetch_hashes` with the logger' do
          expect(securities_request_module).to receive(:fetch_hashes).with(app.logger, anything).and_return([])
          call_method
        end
        it 'calls `fetch_hashes` with the result of `requests_query`' do
          expect(securities_request_module).to receive(:fetch_hashes).with(anything, request_query).and_return([])
          call_method
        end
        it 'calls `requests_query` with the member id' do
          expect(securities_request_module).to receive(:requests_query).with(member_id, any_args).and_return(request_query)
          call_method
        end
        it 'calls `requests_query` with the flattened array for `MAPIRequestStatus::AUTHORIZED` if no status is passed' do
          statuses = Array.wrap(MAPI::Services::Member::SecuritiesRequests::MAPIRequestStatus::AUTHORIZED).flatten.uniq
          expect(securities_request_module).to receive(:requests_query).with(anything, statuses, anything).and_return(request_query)
          call_method
        end
        it 'calls `requests_query` with the flattened array for `MAPIRequestStatus::AWAITING_AUTHORIZATION` if that status is passed' do
          statuses = Array.wrap(MAPI::Services::Member::SecuritiesRequests::MAPIRequestStatus::AWAITING_AUTHORIZATION).flatten.uniq
          expect(securities_request_module).to receive(:requests_query).with(anything, statuses, anything).and_return(request_query)
          MAPI::Services::Member::SecuritiesRequests.requests(app, member_id, MAPI::Services::Member::SecuritiesRequests::MAPIRequestStatus::AWAITING_AUTHORIZATION)
        end
        it 'calls `requests_query` with the date range if one is passed' do
          end_date = (Time.zone.today - rand(10..20).days)
          start_date = (end_date - rand(1..25).years)
          date_range = (start_date..end_date)
          expect(securities_request_module).to receive(:requests_query).with(anything, anything, date_range).and_return(request_query)
          MAPI::Services::Member::SecuritiesRequests.requests(app, member_id, nil, date_range)
        end
        it 'calls `requests_query` with a date range encompassing the last week if no range is passed' do
          end_date = Time.zone.today
          start_date = end_date - 7.days
          date_range = (start_date..end_date)
          expect(securities_request_module).to receive(:requests_query).with(anything, anything, date_range).and_return(request_query)
          call_method
        end
        it 'returns a mapped hash value for each request it finds' do
          n = rand(1..10)
          fetched_hashes = []
          n.times { fetched_hashes << {} }
          allow(securities_request_module).to receive(:fetch_hashes).and_return(fetched_hashes)
          allow(securities_request_module).to receive(:map_hash_values).and_return({})
          expect(call_method.length).to eq(n)
        end
        it 'passes each request to `map_hash_values` with the `REQUEST_VALUE_MAPPING` and an arg of `true` for downcasing' do
          request = double('request')
          mapping = MAPI::Services::Member::SecuritiesRequests::REQUEST_VALUE_MAPPING
          allow(securities_request_module).to receive(:fetch_hashes).and_return([request])
          expect(securities_request_module).to receive(:map_hash_values).with(request, mapping, true).and_return({})
          call_method
        end
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.requests_query`' do
      it 'constructs proper SQL based on the member_id, status array and date range it is passed' do
        status_array = [SecureRandom.hex, SecureRandom.hex, SecureRandom.hex]
        quoted_statuses = status_array.collect { |status| "'#{status}'" }.join(',')
        end_date = Time.zone.today - rand(1..10).days
        start_date = end_date - rand(1..10).days
        date_range = (start_date..end_date)

        sql = <<-SQL
            SELECT HEADER_ID AS REQUEST_ID, FORM_TYPE, SETTLE_DATE, CREATED_DATE AS SUBMITTED_DATE, CREATED_BY_NAME AS SUBMITTED_BY,
            SIGNED_BY_NAME AS AUTHORIZED_BY, SIGNED_DATE AS AUTHORIZED_DATE, STATUS FROM SAFEKEEPING.SSK_WEB_FORM_HEADER
            WHERE FHLB_ID = #{member_id} AND STATUS IN (#{quoted_statuses}) AND SETTLE_DATE >= TO_DATE('#{start_date}','YYYY-MM-DD HH24:MI:SS')
            AND SETTLE_DATE <= TO_DATE('#{end_date}','YYYY-MM-DD HH24:MI:SS')
        SQL
        expect(MAPI::Services::Member::SecuritiesRequests.requests_query(member_id, status_array, date_range)).to eq(sql)
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.create_release`' do
      let(:app) { double(MAPI::ServiceApp, logger: double('logger')) }
      let(:member_id) { rand(9999..99999) }
      let(:header_id) { rand(9999..99999) }
      let(:detail_id) { rand(9999..99999) }
      let(:trade_date) { (Time.zone.today - rand(1..10).days).strftime }
      let(:settlement_date) { (Time.zone.today - rand(1..10).days).strftime }
      let(:broker_instructions) { { 'transaction_code' => rand(0..1) == 0 ? 'standard' : 'repo',
                                    'trade_date' => trade_date,
                                    'settlement_type' => rand(0..1) == 0 ? 'free' : 'vs_payment',
                                    'settlement_date' => settlement_date } }
      let(:delivery_type) { [ 'fed', 'dtc', 'mutual_fund', 'physical_securities' ][rand(0..3)] }
      let(:delivery_columns) { [ SecureRandom.hex, SecureRandom.hex, SecureRandom.hex ] }
      let(:delivery_values) { [ SecureRandom.hex, SecureRandom.hex, SecureRandom.hex ] }
      let(:security) { {  'cusip' => SecureRandom.hex,
                          'description' => SecureRandom.hex,
                          'original_par' => rand(1..100000) + rand.round(2),
                          'payment_amount' => rand(1..100000) + rand.round(2) } }
      let(:required_delivery_keys) { [ 'a', 'b', 'c' ] }
      let(:delivery_columns) { MAPI::Services::Member::SecuritiesRequests.delivery_type_mapping(delivery_type).keys }
      let(:delivery_values) { MAPI::Services::Member::SecuritiesRequests.delivery_type_mapping(delivery_type).values }
      let(:form_type) { MAPI::Services::Member::SecuritiesRequests::SSKFormType::SecuritiesRelease }
      let(:user_name) {  SecureRandom.hex }
      let(:full_name) { SecureRandom.hex }
      let(:session_id) { SecureRandom.hex }
      let(:pledged_adx_id) { rand(1000..10000) }
      let(:ssk_id) { rand(1000..10000) }

      describe '`delivery_keys_for_delivery_type`' do
        it 'returns the correct delivery types for `SSKDeliverTo::FED`' do
          expect(MAPI::Services::Member::SecuritiesRequests.delivery_keys_for_delivery_type('fed')).to eq(
            [ 'account_number', 'clearing_agent_fed_wire_address', 'aba_number' ])
        end

        it 'returns the correct delivery types for `SSKDeliverTo::DTC`' do
          expect(MAPI::Services::Member::SecuritiesRequests.delivery_keys_for_delivery_type('dtc')).to eq(
            [ 'account_number', 'clearing_agent_participant_number' ])
        end

        it 'returns the correct delivery types for `SSKDeliverTo::MUTUAL_FUND`' do
          expect(MAPI::Services::Member::SecuritiesRequests.delivery_keys_for_delivery_type('mutual_fund')).to eq(
            [ 'account_number', 'mutual_fund_company' ])
        end

        it 'returns the correct delivery types for `SSKDeliverTo::PHYSICAL_SECURITIES`' do
          expect(MAPI::Services::Member::SecuritiesRequests.delivery_keys_for_delivery_type('physical_securities')).to eq(
            [ 'account_number', 'delivery_bank_agent', 'receiving_bank_agent_name', 'receiving_bank_agent_address' ])
        end
      end

      describe '`insert_release_header_query`' do
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.insert_release_header_query( member_id,
                                                                                                    header_id,
                                                                                                    user_name,
                                                                                                    full_name,
                                                                                                    session_id,
                                                                                                    pledged_adx_id,
                                                                                                    delivery_columns,
                                                                                                    broker_instructions,
                                                                                                    delivery_type,
                                                                                                    delivery_values ) }
        let(:sentinel) { SecureRandom.hex }
        let(:today) { Time.zone.today }

        before do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(SecureRandom.hex)
          allow(Time.zone).to receive(:today).and_return(today)
        end

        it 'expands delivery columns into the insert statement' do
          expect(call_method).to match(
            /\A\s*INSERT\s+INTO\s+SAFEKEEPING\.SSK_WEB_FORM_HEADER\s+\(HEADER_ID,\s+FHLB_ID,\s+STATUS,\s+PLEDGE_TYPE,\s+TRADE_DATE,\s+REQUEST_STATUS,\s+SETTLE_DATE,\s+DELIVER_TO,\s+FORM_TYPE,\s+CREATED_DATE,\s+CREATED_BY,\s+CREATED_BY_NAME,\s+LAST_MODIFIED_BY,\s+LAST_MODIFIED_DATE,\s+LAST_MODIFIED_BY_NAME,\s+PLEDGED_ADX_ID,\s+#{delivery_columns.join(',\s+')}/)
        end

        it 'sets the `header_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(header_id).and_return(sentinel)
          expect(call_method).to match /VALUES\s\(#{sentinel},/
        end

        it 'sets the `member_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(member_id).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){1}#{sentinel},/
        end

        it 'sets the `status`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(MAPI::Services::Member::SecuritiesRequests::SSKRequestStatus::SUBMITTED).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){2}#{sentinel},/
        end

        it 'sets the `transaction_code`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(MAPI::Services::Member::SecuritiesRequests::TRANSACTION_CODE[broker_instructions['transaction_code']]).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){3}#{sentinel},/
        end

        it 'sets the `trade_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(broker_instructions['trade_date']).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){4}#{sentinel},/
        end

        it 'sets the `settlement_type`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(MAPI::Services::Member::SecuritiesRequests::SETTLEMENT_TYPE[broker_instructions['settlement_type']]).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){5}#{sentinel},/
        end

        it 'sets the `settlement_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(broker_instructions['settlement_date']).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){6}#{sentinel},/
        end

        it 'sets the `delivery_type`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(MAPI::Services::Member::SecuritiesRequests::DELIVERY_TYPE[delivery_type]).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){7}#{sentinel},/
        end

        it 'sets the `form_type`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(form_type).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){8}#{sentinel},/
        end

        it 'sets the `created_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(today).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){9}#{sentinel},/
        end

        it 'sets the `created_by`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(user_name).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){10}#{sentinel},/
        end

        it 'sets the `created_by_name`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(full_name).and_return(sentinel)
          expect(call_method).to match /VALUES\s+\((\S+\s+){11}#{sentinel},/
        end

        it 'sets the `last_modified_by`' do
          formatted_modification_by = double('Formatted Modification By')
          quoted_modification_by = SecureRandom.hex
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_modification_by).and_return(formatted_modification_by)
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(formatted_modification_by).and_return(quoted_modification_by)
          expect(call_method).to match /VALUES\s+\((\S+\s+){12}#{quoted_modification_by}/
        end

        it 'sets the `last_modified_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(Time.zone.today)
          expect(call_method).to match /VALUES\s+\((\S+\s+){13}#{Time.zone.today}/
        end

        it 'sets the `last_modified_by_name`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(full_name)
          expect(call_method).to match /VALUES\s+\((\S+\s+){14}#{full_name}/
        end

        it 'sets the `pledged_adx_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(pledged_adx_id)
          expect(call_method).to match /VALUES\s+\((\S+\s+){15}#{pledged_adx_id}/
        end

        describe 'delivery values' do
          before do
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(broker_instructions['trade_date'])
          end
          it 'sets the `delivery_values`' do
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_delivery_values).and_return(delivery_values.join(', '))
            expect(call_method).to match /VALUES\s+\((\S+\s+){16}#{delivery_values.join(',\s+')}/
          end
        end
      end

      describe '`insert_security_query`' do
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.insert_security_query(header_id, detail_id, user_name, session_id, security, ssk_id) }
        let(:sentinel) { SecureRandom.hex }
        let(:today) { Time.zone.today }

        before do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(SecureRandom.hex)
          allow(Time.zone).to receive(:today).and_return(today)
        end

        it 'constructs an insert statement with the appropriate column names' do
          expect(call_method).to match(
            /\A\s*INSERT\s+INTO\s+SAFEKEEPING\.SSK_WEB_FORM_DETAIL\s+\(DETAIL_ID,\s+HEADER_ID,\s+CUSIP,\s+DESCRIPTION,\s+ORIGINAL_PAR,\s+PAYMENT_AMOUNT,\s+CREATED_DATE,\s+CREATED_BY,\s+LAST_MODIFIED_DATE,\s+LAST_MODIFIED_BY/)
        end

        it 'sets the `detail_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(detail_id).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\(#{sentinel},/)
        end

        it 'sets the `header_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(header_id).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){1}#{sentinel},/)
        end

        it 'sets the `cusip`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(security['cusip']).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){2}UPPER\(#{sentinel}\),/)
        end

        it 'sets the `description`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(security['description']).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){3}#{sentinel},/)
        end

        it 'sets the `original_par`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(security['original_par']).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){4}#{sentinel},/)
        end

        it 'sets the `payment_amount`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(security['payment_amount']).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){5}#{sentinel},/)
        end

        it 'sets the `created_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(today).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){6}#{sentinel},/)
        end

        it 'sets the `created_by`' do
          formatted_username = SecureRandom.hex
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_username).and_return(formatted_username)
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(formatted_username).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){7}#{sentinel},/)
        end

        it 'sets the `last_modified_date`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(today).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){8}#{sentinel},/)
        end

        it 'sets the `last_modified_by`' do
          formatted_modification_by = double('Formatted Modification By')
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_modification_by).and_return(formatted_modification_by)
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(formatted_modification_by).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){9}#{sentinel},/)
        end
        it 'sets the `ssk_id`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(ssk_id).and_return(sentinel)
          expect(call_method).to match(/VALUES\s+\((\S+\s+){10}#{sentinel}/)
        end
      end

      describe '`format_delivery_columns`' do
        let(:provided_delivery_keys) { rand(1..5).times.map { SecureRandom.hex } }
        let(:delivery_type) { MAPI::Services::Member::SecuritiesRequests::DELIVERY_TYPE.keys[rand(0..3)] }
        let(:required_delivery_keys) { MAPI::Services::Member::SecuritiesRequests.delivery_keys_for_delivery_type(delivery_type) }
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.format_delivery_columns(delivery_type,
          required_delivery_keys, provided_delivery_keys) }

        it 'raises an `ArgumentError` if required keys are missing' do
          expect { call_method }.to raise_error(ArgumentError, /delivery_instructions must contain \S+/)
        end

        context 'maps values correctly' do
          let(:provided_delivery_keys) { MAPI::Services::Member::SecuritiesRequests.delivery_keys_for_delivery_type(delivery_type) }
          it 'maps values using delivery type mappings' do
            expect(call_method).to eq(
              required_delivery_keys.map { |key|
                MAPI::Services::Member::SecuritiesRequests.delivery_type_mapping(delivery_type)[key] })
          end
        end
      end

      describe '`format_delivery_values`' do
        let(:delivery_instruction_value) { SecureRandom.hex }
        let(:d1) { SecureRandom.hex }
        let(:d2) { SecureRandom.hex }
        let(:d3) { SecureRandom.hex }
        let(:delivery_instructions) { { 'a' => d1, 'b' => d2, 'c' => d3 } }

        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.format_delivery_values(required_delivery_keys,
          delivery_instructions) }

        it 'calls `quote` on the delivery instruction value' do
          [d1, d2, d3].each do |key|
            expect(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(key)
          end
          call_method
        end

        it 'maps keys to values in `delivery_instructions`' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(delivery_instruction_value)
          expect(call_method).to eq([delivery_instruction_value, delivery_instruction_value, delivery_instruction_value])
        end
      end

      describe '`format_modification_by` class method' do
        let(:username) { double('Username') }
        let(:formatted_username) { SecureRandom.hex(5) }
        let(:session_id) { SecureRandom.hex(5) }
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.format_modification_by(username, session_id) }
        before do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_username).with(username).and_return(formatted_username)
        end
        it 'calls `format_user_name` with the supplied `username`' do
          expect(MAPI::Services::Member::SecuritiesRequests).to receive(:format_username).with(username).and_return(formatted_username)
          call_method
        end
        it 'adds a separator and the `session_id` to the formatted username' do
          expect(call_method).to eq("#{formatted_username}\\\\#{session_id}")
        end
        it 'truncates the formatted modification_by to `LAST_MODIFIED_BY_MAX_LENGTH`' do
          long_session_id = SecureRandom.hex
          result = MAPI::Services::Member::SecuritiesRequests.format_modification_by(username, long_session_id)
          truncated_result = "#{formatted_username}\\\\#{long_session_id}"[0..MAPI::Services::Member::SecuritiesRequests::LAST_MODIFIED_BY_MAX_LENGTH-1]
          expect(result).to eq(truncated_result)
        end
      end
      describe '`format_username` class method' do
        let(:username) { SecureRandom.hex.upcase }
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.format_username(username)}
        it 'downcases the supplied username' do
          expect(call_method).to eq(username.downcase)
        end
      end

      context 'executing a single result sql statement' do
        let(:sql) { double('SQL Statement') }
        let(:description) { SecureRandom.hex }
        let(:single_result) { double('The Single Result') }
        let(:results_array) { instance_double(Array, first: single_result) }
        let(:cursor) { double('cursor', fetch: results_array) }
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.execute_sql_single_result(app, sql, description) }

        before do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger, sql).and_return(cursor)
        end

        it 'raises an error if sequence call returns nil' do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger, sql).and_return(nil)
          expect { call_method }.to raise_error(MAPI::Shared::Errors::SQLError, "#{description} returned nil")
        end

        it 'calls `fetch` on the cusor' do
          expect(cursor).to receive(:fetch).and_return(results_array)
          call_method
        end

        it 'raises an error if `fetch` returns nil' do
          allow(cursor).to receive(:fetch).and_return(nil)
          expect { call_method }.to raise_error(MAPI::Shared::Errors::SQLError, "Calling fetch on the cursor returned nil")
        end

        context 'handling the results array' do
          before do
            allow(cursor).to receive(:fetch).and_return(results_array)
          end

          it 'calls `first` on the results array' do
            expect(results_array).to receive(:first).and_return(single_result)
            call_method
          end

          it 'raises an error if calling `first` on results returns nil' do
            allow(results_array).to receive(:first).and_return(nil)
            expect { call_method }.to raise_error(MAPI::Shared::Errors::SQLError, "Calling first on the record set returned nil")
          end

          context 'gets the record' do
            before do
              allow(results_array).to receive(:first).and_return(single_result)
            end

            it 'returns result' do
              expect(call_method).to eq(single_result)
            end
          end
        end
      end

      describe '`pledged_adx_query`' do
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.pledged_adx_query(member_id) }

        before do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(member_id)
        end

        it 'constructs the appropriate sql' do
          expect(call_method).to eq(<<-SQL
            SELECT ADX.ADX_ID
            FROM SAFEKEEPING.ACCOUNT_DOCKET_XREF ADX, SAFEKEEPING.BTC_ACCOUNT_TYPE BAT, SAFEKEEPING.CUSTOMER_PROFILE CP
            WHERE ADX.BAT_ID = BAT.BAT_ID
            AND ADX.CP_ID = CP.CP_ID
            AND CP.FHLB_ID = #{member_id}
            AND UPPER(SUBSTR(BAT.BAT_ACCOUNT_TYPE,1,1)) = 'P'
            AND CONCAT(TRIM(TRANSLATE(ADX.ADX_BTC_ACCOUNT_NUMBER,' 0123456789',' ')), '*') = '*'
            AND (BAT.BAT_ACCOUNT_TYPE NOT LIKE '%DB%' AND BAT.BAT_ACCOUNT_TYPE NOT LIKE '%REIT%')
            ORDER BY TO_NUMBER(ADX.ADX_BTC_ACCOUNT_NUMBER) ASC
            SQL
          )
        end
      end

      describe '`ssk_id_query`' do
        let(:cusip) { SecureRandom.hex }
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.ssk_id_query(member_id, pledged_adx_id, cusip) }

        before do
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(member_id).and_return(member_id)
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(pledged_adx_id).and_return(pledged_adx_id)
          allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(cusip).and_return(cusip)
        end

        it 'constructs the appropriate sql' do
          expect(call_method).to eq(<<-SQL
            SELECT SSK.SSK_ID
            FROM SAFEKEEPING.SSK SSK, SAFEKEEPING.SSK_TRANS SSKT
            WHERE UPPER(SSK.SSK_CUSIP) = UPPER(#{cusip})
            AND SSK.FHLB_ID = #{member_id}
            AND SSK.ADX_ID = #{pledged_adx_id}
            AND SSKT.SSK_ID = SSK.SSK_ID
            AND SSKT.SSX_BTC_DATE = (SELECT MAX(SSX_BTC_DATE) FROM SAFEKEEPING.SSK_TRANS)
            SQL
          )
        end
      end

      describe '`consolidate_broker_wire_address`' do
        let(:delivery_instructions) {{
          foo: SecureRandom.hex,
          bar: SecureRandom.hex
        }}
        let(:call_method) { securities_request_module.consolidate_broker_wire_address(delivery_instructions) }
        describe 'when the `delivery_instructions` hash does not contain keys found in BROKER_WIRE_ADDRESS_FIELDS' do
          it 'does nothing to the delivery_instructions hash' do
            unmutated_delivery_instructions = delivery_instructions.clone
            call_method
            expect(delivery_instructions).to eq(unmutated_delivery_instructions)
          end
        end
        describe 'when the `delivery_instructions` hash contains keys found in BROKER_WIRE_ADDRESS_FIELDS' do
          let(:address_1) { SecureRandom.hex }
          let(:address_2) { SecureRandom.hex }
          before do
            delivery_instructions['clearing_agent_fed_wire_address_1'] = address_1
            delivery_instructions['clearing_agent_fed_wire_address_2'] = address_2
          end
          it 'deletes the `clearing_agent_fed_wire_address_1` from the hash' do
            expect(delivery_instructions['clearing_agent_fed_wire_address_1']).to eq(address_1)
            call_method
            expect(delivery_instructions).not_to have_key('clearing_agent_fed_wire_address_1')
          end
          it 'deletes the `clearing_agent_fed_wire_address_2` from the hash' do
            expect(delivery_instructions['clearing_agent_fed_wire_address_2']).to eq(address_2)
            call_method
            expect(delivery_instructions).not_to have_key('clearing_agent_fed_wire_address_2')
          end
          it 'adds a `clearing_agent_fed_wire_address` value to the hash that joins `clearing_agent_fed_wire_address_1` and `clearing_agent_fed_wire_address_2` with a `/` character' do
            expect(delivery_instructions).not_to have_key('clearing_agent_fed_wire_address')
            call_method
            expect(delivery_instructions['clearing_agent_fed_wire_address']).to eq([address_1, address_2].join('/'))
          end
        end

      end

      describe '`create_release method`' do
        let(:app) { double(MAPI::ServiceApp, logger: double('logger')) }
        let(:member_id) { rand(100000..999999) }
        let(:delivery_type) { MAPI::Services::Member::SecuritiesRequests::DELIVERY_TYPE.keys[rand(0..3)] }
        let(:delivery_instructions) {
          MAPI::Services::Member::SecuritiesRequests.delivery_keys_for_delivery_type(delivery_type).map do |key|
            [key, SecureRandom.hex]
          end.to_h.merge('delivery_type' => delivery_type) }
        let(:securities) { [ security, security, security ]}
        let(:method_params) { [ app,
                                member_id,
                                user_name,
                                full_name,
                                session_id,
                                broker_instructions,
                                delivery_instructions,
                                securities ] }
        let(:call_method) { MAPI::Services::Member::SecuritiesRequests.create_release(*method_params) }
        context 'validations' do
          before do
            allow(securities_request_module).to receive(:should_fake?).and_return(true)
          end

          it 'calls `consolidate_broker_wire_address` with the provided `delivery_instructions`' do
            expect(securities_request_module).to receive(:consolidate_broker_wire_address).with(delivery_instructions)
            call_method
          end

          it 'raises an error if `broker_instructions` is nil' do
            method_params[5] = nil
            expect{ call_method }.to raise_error(ArgumentError, "broker_instructions must be a non-empty hash")
          end

          it 'raises an error if `delivery_instructions` is nil' do
            method_params[6] = nil
            expect{ call_method }.to raise_error(ArgumentError, "delivery_instructions must be a non-empty hash")
          end

          it 'raises an error if something is missing' do
            broker_instructions.delete(broker_instructions.keys[rand(0..3)])
            expect{ call_method }.to raise_error(ArgumentError, /broker_instructions must contain a value for \S+/)
          end


          it 'raises an error if `transaction_code` is out of range' do
            broker_instructions['transaction_code'] = SecureRandom.hex
            expect{ call_method }.to raise_error(ArgumentError, /transaction_code must be set to one of the following values: \S/)
          end

          it 'raises an error if `settlement_type` is out of range' do
            broker_instructions['settlement_type'] = SecureRandom.hex
            expect{ call_method }.to raise_error(ArgumentError, /settlement_type must be set to one of the following values: \S/)
          end

          it 'raises an error if `delivery_type` is out of range' do
            delivery_instructions['delivery_type'] = SecureRandom.hex
            expect{ call_method }.to raise_error(ArgumentError, /delivery_instructions must contain the key delivery_type set to one of \S/)
          end

          it 'raises an error if `securities` is nil' do
            method_params[7] = nil
            expect{ call_method }.to raise_error(ArgumentError, "securities must be an array containing at least one security")
          end

          context 'empty `securities`' do
            it 'raises an error if `securities` is empty' do
              method_params[7] = []
              expect{ call_method }.to raise_error(ArgumentError, "securities must be an array containing at least one security")
            end
          end

          context do
            before do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_delivery_columns).and_return(
                delivery_columns)
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_delivery_values).and_return(
                delivery_values)
            end

            it 'calls `dateify` on `trade_date`' do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:dateify).with(settlement_date)
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:dateify).with(trade_date)
              call_method
            end

            it 'calls `dateify` on `settlement_date`' do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:dateify).with(trade_date)
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:dateify).with(settlement_date)
              call_method
            end

            it 'calls `delete(:delivery_type)` on `delivery_instructions`' do
              expect(delivery_instructions).to receive(:delete).with('delivery_type').and_return(delivery_type)
              call_method
            end

            it 'raises an `ArgumentError` if `delivery_type` is out of range' do
              allow(delivery_instructions).to receive(:delete).with('delivery_type').and_return(SecureRandom.hex)
              expect { call_method }.to raise_error(ArgumentError, "delivery_instructions must contain the key delivery_type set to one of fed, dtc, mutual_fund, physical_securities")
            end
          end

          context 'securities validations' do
            it 'raises an `ArgumentError` if securities is nil' do
              method_params[7] = nil
              expect { call_method }.to raise_error(ArgumentError, "securities must be an array containing at least one security")
            end

            it 'raises an `ArgumentError` if securities is not an array' do
              method_params[7] = {}
              expect { call_method }.to raise_error(ArgumentError, "securities must be an array containing at least one security")
            end


            it 'raises an `ArgumentError` if the securities array is empty' do
              method_params[7] = []
              expect { call_method }.to raise_error(ArgumentError, "securities must be an array containing at least one security")
            end

            it 'raises an `ArgumentError` if the securities array contains a `nil`' do
              method_params[7] = [ security, nil, security ]
              expect { call_method }.to raise_error(ArgumentError, "each security must be a non-empty hash")
            end

            it 'raises an `ArgumentError` if the securities array contains a non-hash value' do
              method_params[7] = [ security, [], security ]
              expect { call_method }.to raise_error(ArgumentError, "each security must be a non-empty hash")
            end

            context do
              let(:broker_instructions) { { 'transaction_code' => rand(0..1) == 0 ? 'standard' : 'repo',
                                            'trade_date' => trade_date,
                                            'settlement_type' => 'free',
                                            'settlement_date' => settlement_date } }
              let(:security_without_cusip) { { 'description' => SecureRandom.hex,
                                               'original_par' => rand(1..100000) + rand.round(2),
                                               'payment_amount' => rand(1..100000) + rand.round(2) } }
              let(:securities) { [ security, security_without_cusip, security ] }

              it 'raises an `ArgumentError` if a security is missing a key' do
                expect { call_method }.to raise_error(ArgumentError, /each security must consist of a hash containing a value for \S+/)
              end

              it 'raises an `ArgumentError` if `settlement_type` is `vs_payment` and `payment_amount` is missing' do
                broker_instructions['settlement_type'] = 'vs_payment'
                security['payment_amount'] = nil
                expect { call_method }.to raise_error(ArgumentError, /each security must consist of a hash containing a value for payment_amount/)
              end
            end
          end
          it 'passes all validations' do
            expect { call_method }.to_not raise_error
          end
        end

        context 'preparing and executing SQL' do
          let(:next_id) { double('Next ID') }
          let(:sequence_result) { double('Sequence Result', to_i: next_id) }
          let(:pledged_adx_sql) { double('Pledged ADX SQL') }
          let(:ssk_sql) { double('SSK SQL') }
          before do
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_delivery_columns).and_return(
              delivery_columns)
            allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_delivery_values).and_return(
              delivery_values)
            allow(securities_request_module).to receive(:should_fake?).and_return(false)
            allow(securities_request_module).to receive(:pledged_adx_query).with(member_id).and_return(pledged_adx_sql)
            allow(securities_request_module).to receive(:ssk_id_query).with(member_id, pledged_adx_id, security['cusip']).
              exactly(3).times.and_return(ssk_sql)
            allow(securities_request_module).to receive(:execute_sql_single_result).with(
              app,
              MAPI::Services::Member::SecuritiesRequests::NEXT_ID_SQL,
              "Next ID Sequence").and_return(sequence_result)
            allow(securities_request_module).to receive(:execute_sql_single_result).with(
              app,
              pledged_adx_sql,
              "Pledged ADX ID").and_return(pledged_adx_id)
            allow(securities_request_module).to receive(:execute_sql_single_result).with(
              app,
              ssk_sql,
              "SSK ID").and_return(ssk_id)
          end

          context 'prepares SQL' do
            before do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(any_args).and_return(true)
            end

            it 'calls `insert_release_header_query`' do
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:insert_release_header_query).with(
                member_id,
                next_id,
                user_name,
                full_name,
                session_id,
                pledged_adx_id,
                delivery_columns,
                broker_instructions,
                delivery_type,
                delivery_values)
              call_method
            end

            it 'calls `insert_security_query`' do
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:insert_security_query).with(next_id,
                next_id, user_name, session_id, security, ssk_id).exactly(3).times
              call_method
            end
          end

          context 'calls `execute_sql`' do
            let(:insert_header_sql) { double('Insert Header SQL') }
            let(:insert_security_sql) { double('Insert Security SQL') }

            before do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:insert_release_header_query).with(
                member_id,
                next_id,
                user_name,
                full_name,
                session_id,
                pledged_adx_id,
                delivery_columns,
                broker_instructions,
                delivery_type,
                delivery_values).and_return(insert_header_sql)
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:insert_security_query).with(next_id,
                next_id, user_name, session_id, security, ssk_id).exactly(3).times.and_return(insert_security_sql)
            end

            it 'inserts the header' do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                insert_security_sql).exactly(3).times.and_return(true)
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                insert_header_sql).and_return(true)
              expect(call_method).to eq(true)
            end

            it 'inserts the securities' do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                insert_header_sql).and_return(true)
              expect(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                insert_security_sql).exactly(3).times.and_return(true)
              expect(call_method).to eq(true)
            end

            it 'raises errors for SQL failures on header insert' do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                insert_header_sql).and_return(false)
              expect { call_method }.to raise_error(Exception)
            end

            it 'raises errors for SQL failures on securities insert' do
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                insert_header_sql).and_return(true)
              allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql).with(app.logger,
                insert_security_sql).and_return(false)
              expect { call_method }.to raise_error(Exception)
            end
          end
        end
      end
    end
    describe 'GET securities/release/%{request_id}' do
      let(:request_id) { rand(1000..99999) }
      let(:response) { instance_double(Hash, to_json: nil) }
      let(:call_endpoint) { get "/member/#{member_id}/securities/release/#{request_id}"}
      before do
        allow(securities_request_module).to receive(:release_details).and_return(response)
      end
      it 'calls `MAPI::Services::Member::SecuritiesRequests.release_details` with an instance of the MAPI::Service app' do
        expect(securities_request_module).to receive(:release_details).with(an_instance_of(MAPI::ServiceApp), any_args)
        call_endpoint
      end
      it 'calls `MAPI::Services::Member::SecuritiesRequests.release_details` with the `member_id` param' do
        expect(securities_request_module).to receive(:release_details).with(anything, member_id, any_args)
        call_endpoint
      end
      it 'calls `MAPI::Services::Member::SecuritiesRequests.release_details` with the `request_id` param' do
        expect(securities_request_module).to receive(:release_details).with(anything, anything, request_id)
        call_endpoint
      end
      it 'returns the results of `MAPI::Services::Member::SecuritiesRequests.release_details` as JSON' do
        json_response = SecureRandom.hex
        allow(response).to receive(:to_json).and_return(json_response)
        call_endpoint
        expect(call_endpoint.body).to eq(json_response)
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.release_request_header_details_query`' do
      let(:member_id) { rand(1000..99999) }
      let(:header_id) { rand(1000..99999) }

      before do
        allow(securities_request_module).to receive(:quote).with(member_id).and_return(member_id)
        allow(securities_request_module).to receive(:quote).with(header_id).and_return(header_id)
      end

      it 'constructs the proper SQL' do
        expected_sql = <<-SQL
            SELECT PLEDGE_TYPE, REQUEST_STATUS, TRADE_DATE, SETTLE_DATE, DELIVER_TO, BROKER_WIRE_ADDR, ABA_NO, DTC_AGENT_PARTICIPANT_NO,
              MUTUAL_FUND_COMPANY, DELIVERY_BANK_AGENT, REC_BANK_AGENT_NAME, REC_BANK_AGENT_ADDR, CREDIT_ACCT_NO1, CREDIT_ACCT_NO2,
              MUTUAL_FUND_ACCT_NO, CREDIT_ACCT_NO3, CREATED_BY, CREATED_BY_NAME
            FROM SAFEKEEPING.SSK_WEB_FORM_HEADER
            WHERE HEADER_ID = #{header_id}
            AND FHLB_ID = #{member_id}
        SQL
        expect(securities_request_module.release_request_header_details_query(member_id, header_id)).to eq(expected_sql)
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.release_request_securities_query`' do
      let(:header_id) { rand(1000..99999) }

      before { allow(securities_request_module).to receive(:quote).with(header_id).and_return(header_id) }

      it 'constructs the proper SQL' do
        expected_sql = <<-SQL
            SELECT CUSIP, DESCRIPTION, ORIGINAL_PAR, PAYMENT_AMOUNT
            FROM SAFEKEEPING.SSK_WEB_FORM_DETAIL
            WHERE HEADER_ID = #{header_id}
        SQL
        expect(securities_request_module.release_request_securities_query(header_id)).to eq(expected_sql)
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.release_details`' do
      let(:request_id) { rand(1000..99999) }
      let(:app) { double(MAPI::ServiceApp, logger: double('logger')) }
      let(:header_details) {{
        'CREATED_BY' => SecureRandom.hex,
        'CREATED_BY_NAME' => SecureRandom.hex,
        'REQUEST_STATUS' => SecureRandom.hex
      }}
      let(:security) { instance_double(Hash) }
      let(:securities) { [security] }
      let(:call_method) { securities_request_module.release_details(app, member_id, request_id) }

      before do
        allow(securities_request_module).to receive(:fake_securities).and_return(securities)
        allow(securities_request_module).to receive(:fake_header_details).and_return(header_details)
        allow(securities_request_module).to receive(:fetch_hashes).and_return(securities)
        allow(securities_request_module).to receive(:fetch_hash).and_return(header_details)
        allow(securities_request_module).to receive(:broker_instructions_from_header_details)
        allow(securities_request_module).to receive(:delivery_instructions_from_header_details)
        allow(securities_request_module).to receive(:format_securities)
        allow(securities_request_module).to receive(:should_fake?).and_return(true)
        allow(securities_request_module).to receive(:map_hash_values).with(header_details, any_args).and_return(header_details)
        allow(securities_request_module).to receive(:map_hash_values).with(security, any_args).and_return(security)
        allow(security).to receive(:with_indifferent_access).and_return(security)
      end

      describe 'when using fake data' do
        before { allow(securities_request_module).to receive(:should_fake?).and_return(true) }

        it 'constructs `fake_securities` using the `request_id` as an arg' do
          expect(securities_request_module).to receive(:fake_securities).with(request_id, anything).and_return(securities)
          call_method
        end
        it 'constructs `fake_securities` using the `REQUEST_STATUS` from the `header_details` as an arg' do
          expect(securities_request_module).to receive(:fake_securities).with(anything, header_details['REQUEST_STATUS']).and_return(securities)
          call_method
        end
        it 'constructs `fake_header_details` using the `request_id` as an arg' do
          expect(securities_request_module).to receive(:fake_header_details).with(request_id, any_args).and_return(header_details)
          call_method
        end
        it 'constructs `fake_header_details` using `Time.zone.today` as an arg' do
          expect(securities_request_module).to receive(:fake_header_details).with(anything, Time.zone.today, any_args).and_return(header_details)
          call_method
        end
        it 'constructs `fake_header_details` using the status for AWAITING_AUTHORIZATION as an arg' do
          expect(securities_request_module).to receive(:fake_header_details).with(anything, anything, securities_request_module::MAPIRequestStatus::AWAITING_AUTHORIZATION.first).and_return(header_details)
          call_method
        end
      end
      describe 'when using real data' do
        let(:release_request_header_details_query) { instance_double(String) }
        let(:release_request_securities_query) { instance_double(String) }
        before do
          allow(securities_request_module).to receive(:should_fake?).and_return(false)
          allow(securities_request_module).to receive(:release_request_header_details_query).and_return(release_request_header_details_query)
          allow(securities_request_module).to receive(:release_request_securities_query).and_return(release_request_securities_query)
        end

        describe 'fetching the `header_details`' do
          it 'calls `fetch_hash` with the logger' do
            expect(securities_request_module).to receive(:fetch_hash).with(app.logger, anything).and_return(header_details)
            call_method
          end
          it 'calls `fetch_hash` with the result of `release_request_header_details_query`' do
            expect(securities_request_module).to receive(:fetch_hash).with(anything, release_request_header_details_query).and_return(header_details)
            call_method
          end
          it 'calls `release_request_header_details_query` with the `member_id`' do
            expect(securities_request_module).to receive(:release_request_header_details_query).with(member_id, anything)
            call_method
          end
          it 'calls `release_request_header_details_query` with the `request_id`' do
            expect(securities_request_module).to receive(:release_request_header_details_query).with(anything, request_id)
            call_method
          end
          it 'raises an exception if `fetch_hash` returns nil' do
            allow(securities_request_module).to receive(:fetch_hash)
            expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, 'No header details found')
          end
        end
        describe 'fetching the `securities`' do
          it 'calls `fetch_hashes` with the logger' do
            expect(securities_request_module).to receive(:fetch_hashes).with(app.logger, anything).and_return(securities)
            call_method
          end
          it 'calls `fetch_hashes` with the result of `release_request_securities_query`' do
            expect(securities_request_module).to receive(:fetch_hashes).with(anything, release_request_securities_query).and_return(securities)
            call_method
          end
          it 'calls `release_request_securities_query` with the `request_id`' do
            expect(securities_request_module).to receive(:release_request_securities_query).with(request_id)
            call_method
          end
          it 'raises an exception if `fetch_hashes` returns nil' do
            allow(securities_request_module).to receive(:fetch_hashes)
            expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, 'No securities found')
          end
        end
      end
      it 'calls `map_hash_values` on the `header_details`' do
        expect(securities_request_module).to receive(:map_hash_values).with(header_details, any_args).and_return(header_details)
        call_method
      end
      it 'calls `map_hash_values` with the `RELEASE_REQUEST_HEADER_MAPPING` for the `header_details`' do
        expect(securities_request_module).to receive(:map_hash_values).with(anything, securities_request_module::RELEASE_REQUEST_HEADER_MAPPING).exactly(:once).and_return(header_details)
        call_method
      end
      it 'calls `map_hash_values` on each security' do
        securities.each do |security|
          expect(securities_request_module).to receive(:map_hash_values).with(security, any_args).and_return(security)
        end
        call_method
      end
      it 'calls `map_hash_values` with the `RELEASE_REQUEST_SECURITIES_MAPPING` for each security' do
        expect(securities_request_module).to receive(:map_hash_values).with(anything, securities_request_module::RELEASE_REQUEST_SECURITIES_MAPPING).exactly(securities.length).and_return(security)
        call_method
      end
      describe 'the returned hash' do
        let(:broker_instructions) { double(Hash) }
        let(:delivery_instructions) { double(Hash) }
        let(:formatted_securities) { double(Array) }
        it 'contains the `request_id` it was passed' do
          expect(call_method[:request_id]).to eq(request_id)
        end
        it 'passes the `header_details` to `broker_instructions_from_header_details`' do
          expect(securities_request_module).to receive(:broker_instructions_from_header_details).with(header_details)
          call_method
        end
        it 'contains `broker_instructions` that are the result of `broker_instructions_from_header_details`' do
          allow(securities_request_module).to receive(:broker_instructions_from_header_details).and_return(broker_instructions)
          expect(call_method[:broker_instructions]).to eq(broker_instructions)
        end
        it 'passes the `header_details` to `delivery_instructions_from_header_details`' do
          expect(securities_request_module).to receive(:delivery_instructions_from_header_details).with(header_details)
          call_method
        end
        it 'contains `broker_instructions` that are the result of `delivery_instructions_from_header_details`' do
          allow(securities_request_module).to receive(:delivery_instructions_from_header_details).and_return(delivery_instructions)
          expect(call_method[:delivery_instructions]).to eq(delivery_instructions)
        end
        it 'passes the securities to the `format_securities` method' do
          expect(securities_request_module).to receive(:format_securities).with(securities)
          call_method
        end
        it 'contains `securities` that are the result of `format_securities`' do
          allow(securities_request_module).to receive(:format_securities).and_return(formatted_securities)
          expect(call_method[:securities]).to eq(formatted_securities)
        end
        it 'contains a `user` hash with a `username` equal to the `CREATED_BY` value in the `header_details`' do
          expect(call_method[:user][:username]).to eq(header_details['CREATED_BY'])
        end
        it 'contains a `user` hash with a `full_name` equal to the `CREATED_BY_NAME` value in the `header_details`' do
          expect(call_method[:user][:full_name]).to eq(header_details['CREATED_BY_NAME'])
        end
        it 'contains a `user` hash with a nil value for `session_id`' do
          expect(call_method[:user][:session_id]).to eq(nil)
        end
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.broker_instructions_from_header_details`' do
      let(:header_details) {{
        'PLEDGE_TYPE' => instance_double(String),
        'REQUEST_STATUS' => instance_double(String),
        'TRADE_DATE' => instance_double(Date),
        'SETTLE_DATE' => instance_double(Date)
      }}
      let(:call_method) { securities_request_module.broker_instructions_from_header_details(header_details) }

      {
        transaction_code: 'PLEDGE_TYPE',
        settlement_type: 'REQUEST_STATUS',
        trade_date: 'TRADE_DATE',
        settlement_date: 'SETTLE_DATE'
      }.each do |key, value|
        it "returns a hash with a `#{key}` equal to the `#{value}` of the passed `header_details`" do
          expect(call_method[key]).to eq(header_details[value])
        end
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.delivery_instructions_from_header_details`' do
      let(:address_1) { SecureRandom.hex }
      let(:address_2) { SecureRandom.hex }
      let(:address_3) { SecureRandom.hex }
      let(:header_details) {{
        'BROKER_WIRE_ADDR' => [address_1, address_2].join('/'),
        'ABA_NO' => instance_double(String),
        'DTC_AGENT_PARTICIPANT_NO' => instance_double(String),
        'MUTUAL_FUND_COMPANY' => instance_double(String),
        'DELIVERY_BANK_AGENT' => instance_double(String),
        'REC_BANK_AGENT_NAME' => instance_double(String),
        'REC_BANK_AGENT_ADDR' => instance_double(String),
        'CREDIT_ACCT_NO1' => instance_double(String),
        'CREDIT_ACCT_NO2' => instance_double(String),
        'MUTUAL_FUND_ACCT_NO' => instance_double(String),
        'CREDIT_ACCT_NO3' => instance_double(String)
      }}
      let(:call_method) { securities_request_module.delivery_instructions_from_header_details(header_details) }
      securities_request_module::DELIVERY_TYPE.keys.each do |delivery_type|
        describe "when the passed header_details hash has a `DELIVER_TO` value of `#{delivery_type}`" do
          before { header_details['DELIVER_TO'] = delivery_type }
          it "returns a hash with a `delivery_type` equal `#{delivery_type}`" do
            expect(call_method[:delivery_type]).to eq(delivery_type)
          end
          securities_request_module.delivery_keys_for_delivery_type(delivery_type).each do |required_key|
            next if required_key == 'clearing_agent_fed_wire_address'
            security_key = securities_request_module.delivery_type_mapping(delivery_type)[required_key]
            it "returns a hash with a `#{required_key}` equal to the `#{security_key}` value of the passed header_details hash" do
              expect(call_method[required_key]).to eq(header_details[security_key])
            end
          end
        end
      end
      describe 'handling the `clearing_agent_fed_wire_address` value' do
        before { header_details['DELIVER_TO'] = 'fed' }
        describe 'when the `clearing_agent_fed_wire_address` header value does not contain the `/` character' do
          before { header_details['BROKER_WIRE_ADDR'] = address_3 }
          it 'assigns the `clearing_agent_fed_wire_address` header value to the `clearing_agent_fed_wire_address_1` field' do
            expect(call_method['clearing_agent_fed_wire_address_1']).to eq(address_3)
          end
          it 'assigns nil to the `clearing_agent_fed_wire_address_2` field' do
            expect(call_method['clearing_agent_fed_wire_address_2']).to be_nil
          end
        end
        describe 'when the `clearing_agent_fed_wire_address` header value contains one `/` character' do
          it 'splits the `clearing_agent_fed_wire_address` header value by the `/` character and assigns `clearing_agent_fed_wire_address_1` the first value' do
            expect(call_method['clearing_agent_fed_wire_address_1']).to eq(address_1)
          end
          it 'splits the `clearing_agent_fed_wire_address` header value by the `/` character and assigns `clearing_agent_fed_wire_address_2` the second value' do
            expect(call_method['clearing_agent_fed_wire_address_2']).to eq(address_2)
          end
        end
        describe 'when the `clearing_agent_fed_wire_address` header value contains more than one `/` character' do
          before { header_details['BROKER_WIRE_ADDR'] = [address_1, address_2, address_3].join('/') }
          it 'splits the `clearing_agent_fed_wire_address` header value by the `/` character and assigns `clearing_agent_fed_wire_address_1` the first value' do
            expect(call_method['clearing_agent_fed_wire_address_1']).to eq(address_1)
          end
          it 'splits the `clearing_agent_fed_wire_address` header value by the `/` character and assigns `clearing_agent_fed_wire_address_2` all remaining values joined by the `/` character' do
            expect(call_method['clearing_agent_fed_wire_address_2']).to eq([address_2, address_3].join('/'))
          end
        end
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.format_securities`' do
      let(:security) {{
        'CUSIP' => instance_double(String),
        'DESCRIPTION' => instance_double(String),
        'ORIGINAL_PAR' => instance_double(Integer),
        'PAYMENT_AMOUNT' => instance_double(Integer)
      }}
      let(:securities) { [security] }
      let(:call_method) { securities_request_module.format_securities(securities) }

      {
        cusip: 'CUSIP',
        description: 'DESCRIPTION',
        original_par: 'ORIGINAL_PAR',
        payment_amount: 'PAYMENT_AMOUNT'
      }.each do |key, value|
        it "returns an array of hashes with a `#{key}` equal to the `#{value}` of each passed security" do
          expect(call_method.length).to be > 0
          call_method.each do |returned_security|
            expect(returned_security[key]).to eq(security[value])
          end
        end
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.fake_header_details`' do
      fake_data = fake('securities_release_request_details')
      names = fake_data['names']
      let(:request_id) { rand(1000..9999)}
      let(:end_date) { Time.zone.today - rand(0..7).days }
      let(:status) { (securities_request_module::MAPIRequestStatus::AUTHORIZED + securities_request_module::MAPIRequestStatus::AWAITING_AUTHORIZATION).sample }
      let(:rng) { instance_double(Random) }
      let(:pledge_type_offset) { rand(0..1) }
      let(:request_status_offset) { rand(0..1) }
      let(:delivery_type_offset) { rand(0..3) }
      let(:aba_number) { rand(10000..99999) }
      let(:participant_number) { rand(10000..99999) }
      let(:account_number) { rand(10000..99999) }
      let(:submitted_date_offset) { rand(0..4) }
      let(:authorized_date_offset) { rand(0..2) }
      let(:created_by_offset) { rand(0..names.length-1) }
      let(:form_type) { rand(70..73) }
      let(:authorized_by_offset) { rand(0..names.length-1) }

      let(:call_method) { securities_request_module.fake_header_details(request_id, end_date, status) }
      before do
        allow(Random).to receive(:new).and_return(rng)
        allow(rng).to receive(:rand).and_return(pledge_type_offset, request_status_offset, delivery_type_offset, aba_number, participant_number, account_number, submitted_date_offset, authorized_date_offset, created_by_offset, form_type, authorized_by_offset)
      end

      it 'constructs a hash with a securities with a `REQUEST_ID` value equal to the passed arg' do
        expect(call_method['REQUEST_ID']).to eq(request_id)
      end
      it 'constructs a hash with a `PLEDGE_TYPE` value' do
        expect(call_method['PLEDGE_TYPE']).to eq(securities_request_module::TRANSACTION_CODE.values[pledge_type_offset])
      end
      it 'constructs a hash with a `REQUEST_STATUS` value' do
        expect(call_method['REQUEST_STATUS']).to eq(securities_request_module::SETTLEMENT_TYPE.values[request_status_offset])
      end
      it 'constructs a hash with a `DELIVER_TO` value' do
        expect(call_method['DELIVER_TO']).to eq(securities_request_module::DELIVERY_TYPE.values[delivery_type_offset])
      end
      it 'constructs a hash with an `ABA_NO` value' do
        expect(call_method['ABA_NO']).to eq(aba_number)
      end
      it 'constructs a hash with a `DTC_AGENT_PARTICIPANT_NO` value' do
        expect(call_method['DTC_AGENT_PARTICIPANT_NO']).to eq(participant_number)
      end
      it 'constructs a hash with a `TRADE_DATE` value' do
        expect(call_method['TRADE_DATE']).to eq(end_date - (submitted_date_offset).days)
      end
      it 'constructs a hash with a `SUBMITTED_DATE` value' do
        expect(call_method['SUBMITTED_DATE']).to eq(end_date - (submitted_date_offset).days)
      end
      it 'constructs a hash with a `CREATED_BY` value' do
        expect(call_method['CREATED_BY']).to eq(fake_data['usernames'][created_by_offset])
      end
      it 'constructs a hash with a `CREATED_BY_NAME` value' do
        expect(call_method['CREATED_BY_NAME']).to eq(names[created_by_offset])
      end
      it 'constructs a hash with a `SUBMITTED_BY` value equal to the `CREATED_BY_NAME`' do
        expect(call_method['SUBMITTED_BY']).to eq(names[created_by_offset])
      end
      it 'constructs a hash with a `FORM_TYPE` value' do
        expect(call_method['FORM_TYPE']).to eq(form_type)
      end
      it 'constructs a hash with a `STATUS` value equal to the passed `status`' do
        expect(call_method['STATUS']).to eq(status)
      end
      [
        'CREDIT_ACCT_NO1',
        'CREDIT_ACCT_NO2',
        'MUTUAL_FUND_ACCT_NO',
        'CREDIT_ACCT_NO3'
      ].each do |key|
        it "constructs a hash with a `#{key}` value" do
          expect(call_method[key]).to eq(account_number)
        end
      end
      {
        'BROKER_WIRE_ADDR' => '0541254875/FIRST TENN',
        'MUTUAL_FUND_COMPANY' => "Mutual Funds R'Us",
        'DELIVERY_BANK_AGENT' => 'MI6',
        'REC_BANK_AGENT_NAME' => 'James Bond',
        'REC_BANK_AGENT_ADDR' => '600 Mulberry Court, Boston, MA, 42893',
      }.each do |key, value|
        it "constructs a hash with a `#{key}` value of `#{value}`" do
          expect(call_method[key]).to eq(value)
        end
      end
      describe 'when an `AUTHORIZED` status is passed' do
        let(:status) { securities_request_module::MAPIRequestStatus::AUTHORIZED.sample }

        it 'constructs a hash with an `AUTHORIZED_DATE` value that is equal to the `SUBMITTED_DATE` plus an offset' do
          submitted_date = end_date - (submitted_date_offset).days
          expect(call_method['AUTHORIZED_DATE']).to eq(submitted_date + (authorized_date_offset).days)
        end
        it 'constructs a hash with a `SETTLE_DATE` value equal to the `AUTHORIZED_DATE` plus one day' do
          authorized_date = end_date - (submitted_date_offset).days + (authorized_date_offset).days
          expect(call_method['SETTLE_DATE']).to eq(authorized_date + 1.day)
        end
        it 'constructs a hash with an `AUTHORIZED_BY` value' do
          expect(call_method['AUTHORIZED_BY']).to eq(fake_data['names'][authorized_by_offset])
        end
      end
      describe 'when an `AWAITING_AUTHORIZATION` status is passed' do
        let(:status) { securities_request_module::MAPIRequestStatus::AWAITING_AUTHORIZATION.sample }

        it 'constructs a hash with a nil value for `AUTHORIZED_DATE`' do
          expect(call_method['AUTHORIZED_DATE']).to be_nil
        end
        it 'constructs a hash with a `SETTLE_DATE` value equal to the `SUBMITTED_DATE` plus one day' do
          submitted_date = end_date - (submitted_date_offset).days
          expect(call_method['SETTLE_DATE']).to eq(submitted_date + 1.day)
        end
        it 'constructs a hash with a nil value for `AUTHORIZED_BY`' do
          expect(call_method['AUTHORIZED_BY']).to be_nil
        end
      end
    end

    describe '`MAPI::Services::Member::SecuritiesRequests.fake_securities`' do
      fake_data = fake('securities_release_request_details')
      let(:request_id) { rand(1000..9999)}
      let(:settlement_type) { securities_request_module::SETTLEMENT_TYPE.values.sample }
      let(:rng) { instance_double(Random) }
      let(:original_par) { rand(10000..99999) }
      let(:cusip_offset) { rand(0..5) }
      let(:description_offset) { rand(0..5) }

      let(:call_method) { securities_request_module.fake_securities(request_id, settlement_type) }
      before do
        allow(Random).to receive(:new).and_return(rng)
        allow(rng).to receive(:rand).and_return(1, original_par, cusip_offset, description_offset)
      end

      it 'constructs an array of securities' do
        n = rand(1..6)
        allow(rng).to receive(:rand).with(1..6).and_return(n)
        expect(call_method.length).to eq(n)
      end
      it 'constructs securities with a `CUSIP` value' do
        results = call_method
        expect(results.length).to be > 0
        results.each do |result|
          expect(result['CUSIP']).to eq(fake_data['cusips'][cusip_offset])
        end
      end
      it 'constructs securities with a `DESCRIPTION` value' do
        results = call_method
        expect(results.length).to be > 0
        results.each do |result|
          expect(result['DESCRIPTION']).to eq(fake_data['descriptions'][description_offset])
        end
      end
      it 'constructs securities with an `ORIGINAL_PAR` value' do
        results = call_method
        expect(results.length).to be > 0
        results.each do |result|
          expect(result['ORIGINAL_PAR']).to eq(original_par)
        end
      end
      describe "when the `settlement_type` is `#{securities_request_module::SSKSettlementType::FREE}`" do
        it 'constructs securities with a nil value for `PAYMENT_AMOUNT`' do
          results = securities_request_module.fake_securities(request_id, securities_request_module::SSKSettlementType::FREE)
          expect(results.length).to be > 0
          results.each do |result|
            expect(result['PAYMENT_AMOUNT']).to be_nil
          end
        end
      end
      describe "when the `settlement_type` is `#{securities_request_module::SSKSettlementType::VS_PAYMENT}`" do
        it 'constructs securities with a nil value for `PAYMENT_AMOUNT`' do
          results = securities_request_module.fake_securities(request_id, securities_request_module::SSKSettlementType::VS_PAYMENT)
          expect(results.length).to be > 0
          results.each do |result|
            expect(result['PAYMENT_AMOUNT']).to eq(original_par - (original_par/3))
          end
        end
      end
    end

    describe '`delete_request_header_details_query` class method' do
      submitted_status = securities_request_module::SSKRequestStatus::SUBMITTED
      let(:header_id) { instance_double(String) }
      let(:member_id) { instance_double(String) }
      let(:sentinel) { SecureRandom.hex }
      let(:call_method) { securities_request_module.delete_request_header_details_query(member_id, header_id) }

      before { allow(securities_request_module).to receive(:quote).and_return(SecureRandom.hex) }

      it 'returns a DELETE query' do
        expect(call_method).to match(/\A\s*DELETE\s+FROM\s+SAFEKEEPING.SSK_WEB_FORM_HEADER\s+/i)
      end
      it 'includes the `header_id` in the WHERE clause' do
        allow(securities_request_module).to receive(:quote).with(header_id).and_return(sentinel)
        expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+HEADER_ID\s+=\s+#{sentinel}(\s+|\z)/)
      end
      it 'includes the `member_id` in the WHERE clause' do
        allow(securities_request_module).to receive(:quote).with(member_id).and_return(sentinel)
        expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+FHLB_ID\s+=\s+#{sentinel}(\s+|\z)/)
      end
      it "includes the `#{submitted_status}` STATUS in the WHERE clause" do
        allow(securities_request_module).to receive(:quote).with(submitted_status).and_return(sentinel)
        expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+STATUS\s+=\s+#{sentinel}(\s+|\z)/)
      end
    end
    describe '`delete_request_securities_query` class method' do
      let(:header_id) { instance_double(String) }
      let(:sentinel) { SecureRandom.hex }
      let(:call_method) { securities_request_module.delete_request_securities_query(header_id) }

      before { allow(securities_request_module).to receive(:quote).and_return(SecureRandom.hex) }

      it 'returns a DELETE query' do
        expect(call_method).to match(/\A\s*DELETE\s+FROM\s+SAFEKEEPING.SSK_WEB_FORM_DETAIL\s+/i)
      end
      it 'includes the `header_id` in the WHERE clause' do
        allow(securities_request_module).to receive(:quote).with(header_id).and_return(sentinel)
        expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+HEADER_ID\s+=\s+#{sentinel}(\s+|\z)/)
      end
    end
    describe '`delete_request` class method' do
      let(:request_id) { rand(1000..9999) }
      let(:member_id) { rand(1000..9999) }
      let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter, transaction: nil, execute: nil) }
      let(:delete_request_securities_query) { instance_double(String) }
      let(:delete_request_header_details_query) { instance_double(String) }
      let(:call_method) { securities_request_module.delete_request(app, member_id, request_id) }
      before do
        allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
        allow(securities_request_module).to receive(:delete_request_securities_query).and_return(delete_request_securities_query)
        allow(securities_request_module).to receive(:delete_request_header_details_query).and_return(delete_request_header_details_query)
      end
      describe 'when `should_fake?` returns true' do
        before { allow(securities_request_module).to receive(:should_fake?).and_return(true) }
        it 'returns true' do
          expect(call_method).to be true
        end
      end
      describe 'when `should_fake?` returns false' do
        before { allow(securities_request_module).to receive(:should_fake?).and_return(false) }
        it 'executes code within a transaction where the `isolation` has been set to `:read_committed`' do
          expect(connection).to receive(:transaction).with(isolation: :read_committed)
          call_method
        end
        describe 'the transaction block' do
          before do
            allow(connection).to receive(:transaction) do |&block|
              begin
                block.call
              rescue ActiveRecord::Rollback
              end
            end
          end
          it 'generates a delete request securities query' do
            expect(securities_request_module).to receive(:delete_request_securities_query).with(request_id)
            call_method
          end
          it 'executes the delete request securities query' do
            allow(securities_request_module).to receive(:delete_request_securities_query).with(request_id).and_return(delete_request_securities_query)
            expect(connection).to receive(:execute).with(delete_request_securities_query)
            call_method
          end
          it 'generates a delete request header details query' do
            expect(securities_request_module).to receive(:delete_request_header_details_query).with(member_id, request_id)
            call_method
          end
          it 'executes the delete request header details query' do
            expect(connection).to receive(:execute).with(delete_request_header_details_query)
            call_method
          end
          it 'rolls back the transaction if the delete request header details query deletes no records' do
            allow(connection).to receive(:execute).with(delete_request_header_details_query).and_return(0)
            allow(connection).to receive(:transaction) do |&block|
              expect{block.call}.to raise_error(ActiveRecord::Rollback, 'No header details found to delete')
            end
            call_method
          end
          it 'returns false if the delete request header details query deletes no records' do
            allow(connection).to receive(:execute).with(delete_request_header_details_query).and_return(0)
            expect(call_method).to be false
          end
          it 'returns true if the delete request header details query deletes at least one record' do
            allow(connection).to receive(:execute).with(delete_request_header_details_query).and_return(1)
            expect(call_method).to be true
          end
        end
      end
    end
  end

  describe '`authorize_request_query` class method' do
    let(:request_id) { double('A Request ID') }
    let(:username) { double('A Username') }
    let(:full_name) { double('A Full Name') }
    let(:session_id) { double('A Session ID') }
    let(:signer_id) { double('A Signer ID') }
    let(:modification_by) { double('A Modification By') }
    let(:sentinel) { SecureRandom.hex }
    let(:today) { Time.zone.today }
    let(:call_method) { MAPI::Services::Member::SecuritiesRequests.authorize_request_query(member_id, request_id, username, full_name, session_id, signer_id) }

    before do
      allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).and_return(SecureRandom.hex)
      allow(MAPI::Services::Member::SecuritiesRequests).to receive(:format_modification_by).with(username, session_id).and_return(modification_by)
      allow(Time.zone).to receive(:today).and_return(today)
    end
    
    it 'returns an UPDATE query' do
      expect(call_method).to match(/\A\s*UPDATE\s+SAFEKEEPING.SSK_WEB_FORM_HEADER\s+SET\s+/i)
    end
    it 'updates the `STATUS`' do
      allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(MAPI::Services::Member::SecuritiesRequests::SSKRequestStatus::SIGNED).and_return(sentinel)
      expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+STATUS\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
    end
    it 'updates the `SIGNED_BY`' do
      allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(signer_id).and_return(sentinel)
      expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+SIGNED_BY\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
    end
    it 'updates the `SIGNED_BY_NAME`' do
      allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(full_name).and_return(sentinel)
      expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+SIGNED_BY_NAME\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
    end
    it 'updates the `SIGNED_DATE`' do
      allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(today).and_return(sentinel)
      expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+SIGNED_DATE\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
    end
    it 'updates the `LAST_MODIFIED_BY`' do
      allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(modification_by).and_return(sentinel)
      expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+LAST_MODIFIED_BY\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
    end
    it 'updates the `LAST_MODIFIED_DATE`' do
      allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(today).and_return(sentinel)
      expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+LAST_MODIFIED_DATE\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
    end
    it 'updates the `LAST_MODIFIED_BY_NAME`' do
      allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(full_name).and_return(sentinel)
      expect(call_method).to match(/\sSET(\s+\S+\s+=\s+\S+\s*,)*\s+LAST_MODIFIED_BY_NAME\s+=\s+#{sentinel}(,|\s+WHERE\s)/i)
    end
    it 'includes the `request_id` in the WHERE clause' do
      allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(request_id).and_return(sentinel)
      expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+HEADER_ID\s+=\s+#{sentinel}(\s+|\z)/)
    end
    it 'includes the `member_id` in the WHERE clause' do
      allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(member_id).and_return(sentinel)
      expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+FHLB_ID\s+=\s+#{sentinel}(\s+|\z)/)
    end
    it 'restricts the updates to unauthorized queries' do
      allow(MAPI::Services::Member::SecuritiesRequests).to receive(:quote).with(MAPI::Services::Member::SecuritiesRequests::SSKRequestStatus::SUBMITTED).and_return(sentinel)
      expect(call_method).to match(/\sWHERE(\s+\S+\s+=\s+\S+\s+AND)*\s+STATUS\s+=\s+#{sentinel}(\s+|\z)/)
    end
  end

  describe '`authorize_request` class method' do
    let(:request_id) { double('A Request ID') }
    let(:username) { double('A Username') }
    let(:full_name) { double('A Full Name') }
    let(:session_id) { double('A Session ID') }
    let(:signer_id) { double('A Signer ID') }
    let(:modification_by) { double('A Modification By') }
    let(:authorization_query) { double('An Authorization Query') }
    let(:call_method) { MAPI::Services::Member::SecuritiesRequests.authorize_request(app, member_id, request_id, username, full_name, session_id) }

    before do
      allow(MAPI::Services::Member::SecuritiesRequests).to receive(:authorize_request_query).and_return(authorization_query)
    end

    describe '`should_fake?` returns true' do
      before do
        allow(MAPI::Services::Member::SecuritiesRequests).to receive(:should_fake?).and_return(true)
      end
      it 'generates an authorization query using `nil` for the signer ID' do
        expect(MAPI::Services::Member::SecuritiesRequests).to receive(:authorize_request_query).with(member_id, request_id, username, full_name, session_id, nil)
        call_method
      end
      it 'does not execute a query' do
        expect(ActiveRecord::Base.connection).to_not receive(:execute)
        call_method
      end
      it 'returns true' do
        expect(call_method).to be(true)
      end
    end
    describe '`should_fake?` returns false' do
      let(:signer_id) { double('A Signer ID') }
      let(:signer_id_query) { double('A Signer ID Query') }
      before do
        allow(MAPI::Services::Member::SecuritiesRequests).to receive(:should_fake?).and_return(false)
        allow(MAPI::Services::Users).to receive(:signer_id_query).with(username).and_return(signer_id_query)
        allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql_single_result).with(app, signer_id_query, 'Signer ID').and_return(signer_id)
        allow(ActiveRecord::Base.connection).to receive(:execute).with(authorization_query).and_return(1)
      end
      it 'generates a signer ID query' do
        expect(MAPI::Services::Users).to receive(:signer_id_query).with(username).and_return(signer_id_query)
        call_method
      end
      it 'converts the username into a signer ID' do
        expect(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql_single_result).with(app, signer_id_query, 'Signer ID').and_return(signer_id)
        call_method
      end
      it 'raises an error if the signer ID is not found' do
        allow(MAPI::Services::Member::SecuritiesRequests).to receive(:execute_sql_single_result).with(app, signer_id_query, 'Signer ID').and_raise(MAPI::Shared::Errors::SQLError)
        expect{call_method}.to raise_error(/signer not found/i)
      end
      it 'generates an authorization query using the signer ID' do
        expect(MAPI::Services::Member::SecuritiesRequests).to receive(:authorize_request_query).with(member_id, request_id, username, full_name, session_id, signer_id).and_return(authorization_query)
        call_method
      end
      it 'returns true if executing the query updates one row' do
        expect(call_method).to be(true)
      end
      it 'returns false if executing the query updates no rows' do
        allow(ActiveRecord::Base.connection).to receive(:execute).with(authorization_query).and_return(0)
        expect(call_method).to be(false)
      end
    end
  end
end