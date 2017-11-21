require 'net/sftp'
class MortgagesController < ApplicationController
  include CustomFormattingHelper
  include ContactInformationHelper

  before_action do
    set_active_nav(:mortgages)
    @html_class ||= 'white-background'
  end

  before_action only: [:new] do
    authorize :mortgage, :request?
  end

  PLEDGE_TYPE_MAPPING = {
    specific: I18n.t('mortgages.new.transaction.pledge_types.specific'),
    blanket_lien: I18n.t('mortgages.new.transaction.pledge_types.blanket_lien')
  }.with_indifferent_access

  PLEDGE_TYPE_DROPDOWN = [[I18n.t('mortgages.new.transaction.pledge_types.specific'), 'specific']]
  
  BLANKET_LIEN_DROPDOWN_OPTION = [I18n.t('mortgages.new.transaction.pledge_types.blanket_lien'), 'blanket_lien']

  MCU_TYPE_MAPPING = {
    complete: I18n.t('mortgages.new.transaction.mcu_types.complete'),
    update: I18n.t('mortgages.new.transaction.mcu_types.update'),
    pledge: I18n.t('mortgages.new.transaction.mcu_types.pledge'),
    depledge: I18n.t('mortgages.new.transaction.mcu_types.depledge'),
    add: I18n.t('mortgages.new.transaction.mcu_types.add'),
    delete: I18n.t('mortgages.new.transaction.mcu_types.delete'),
    renumber: I18n.t('mortgages.new.transaction.mcu_types.renumber')
  }.with_indifferent_access

  PROGRAM_TYPE_MAPPING = {
    standard: I18n.t('mortgages.new.transaction.program_types.standard'),
    loans_held: I18n.t('mortgages.new.transaction.program_types.loans_held')
  }.with_indifferent_access

  STATUS_MAPPING = {
    processing: I18n.t('mortgages.view.transaction_details.status.processing'),
    review: I18n.t('mortgages.view.transaction_details.status.review'),
    committed: I18n.t('mortgages.view.transaction_details.status.committed'),
    canceled: I18n.t('mortgages.view.transaction_details.status.canceled')
  }.with_indifferent_access

  ACCEPTED_UPLOAD_MIMETYPES = [
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-excel',
    'text/csv',
    'application/vnd.oasis.opendocument.spreadsheet',
    'text/plain',
    'application/x-compressed',
    'application/x-zip-compressed',
    'application/zip',
    'multipart/x-zip'
  ].freeze

  # GET
  def manage
    @title = t('mortgages.manage.title')
    member_info = MemberBalanceService.new(current_member_id, request).mcu_member_info
    unless member_info.present?
      @error = 'No MCU member info returned from the MCM message bus'
      logger.error(@error)
    else
      @due_datetime = member_info[:mcuDueDate].try(:to_date)
      @extension_datetime = member_info[:mcuExtendedDate].try(:to_date)
      member_balances = MemberBalanceService.new(current_member_id, request)
      mcu_status = member_balances.mcu_member_status
      rows = if mcu_status.present?
        mcu_status.collect do |status|
          status = translated_mcu_transaction(status)
        {
          columns: [
            {value: status[:transactionId], type: nil},
            {value: status[:mcuType], type: nil},
            {value: status[:authorizedBy], type: nil},
            {value: status[:authorizedOn], type: :date},
            {value: status[:status], type: nil},
            {value: status[:numberOfLoans], type: nil},
            {value: status[:numberOfErrors], type: nil},
            {value: [[I18n.t('mortgages.manage.actions.view_details'), mcu_view_transaction_path(transactionId: status[:transactionId])]], type: :link_list}
          ]
        }
        end
      else
        []
      end
      @table_data = {
        column_headings: [
          t('mortgages.manage.transaction_number'),
          t('mortgages.manage.upload_type'),
          t('mortgages.manage.authorized_by'),
          t('mortgages.manage.authorized_on'),
          t('mortgages.manage.status'),
          t('mortgages.manage.number_of_loans'),
          t('mortgages.manage.number_of_errors'),
          t('mortgages.manage.action')
        ],
        rows: rows
      }
    end
  end

  # GET
  def new
    @title = t('mortgages.new.title')
    member_info = MemberBalanceService.new(current_member_id, request).mcu_member_info
    unless member_info.present?
      @error = 'No MCU member info returned from the MCM message bus'
      logger.error(@error)
    else
      @due_datetime = Time.zone.parse(member_info['mcuDueDate'])
      @extension_datetime = Time.zone.parse(member_info['mcuExtendedDate'])
      @pledge_type_dropdown_options = PLEDGE_TYPE_DROPDOWN
      @pledge_type_dropdown_options << BLANKET_LIEN_DROPDOWN_OPTION if member_info['blanketLien']
      @pledge_type_dropdown_options.uniq!
      file_types = member_info['mcuuFileTypes']
      @mcu_type_dropdown_options = file_types.map { |type| type['nameSpecific'] }.zip(file_types.map { |type| "#{type['id']}_#{type['value']}" })
      @program_type_dropdowns = Hash[file_types.map { |type| "#{type['id']}_#{type['value']}" }.zip(file_types.map { |type| [[type['pledgeTypes'][0], type['pledgeTypes'][0]]] })]
      @accepted_upload_mimetypes = ACCEPTED_UPLOAD_MIMETYPES.join(', ')
      @session_elevated = session_elevated?
    end
  end

  # GET
  def view
    @title = t('mortgages.view.title')
    member_balances = MemberBalanceService.new(current_member_id, request)
    mcu_transactions = member_balances.mcu_member_status
    unless mcu_transactions.present?
      @error = 'There has been an error and MortgagesController#view has encountered nil. Check error logs.'
      logger.error(@error)
    else
      transaction_details = mcu_transactions.select{ |transaction| transaction[:transactionId].to_s == params[:transactionId].to_s}.first
      unless transaction_details.present?
        @error = "No matching MCU Status found for MCU with transactionId: #{params[:transactionId]}"
        logger.error(@error)
      else        
        @transaction_details = translated_mcu_transaction(transaction_details)
      end
    end
  end

  # POST
  def upload
    @result = {}
    unless session_elevated?
      @securid_status = securid_perform_check
      if !@securid_status.nil? && @securid_status != RSA::SecurID::Session::AUTHENTICATED
        redirect_to mcu_new_url
        return
      end
    end
    member_balances = MemberBalanceService.new(current_member_id, request)
    transaction_id_response = member_balances.mcu_transaction_id
    unless transaction_id_response.present?
      logger.error('No transaction id response returned from the MCM message bus')
      @result[:success] = false
      @result[:message] = I18n.t('mortgages.new.upload.error_html', email: collateral_operations_email, phone: collateral_operations_phone_number).html_safe
    else
      @transaction_id = transaction_id_response[:transaction_id]
      unless @transaction_id.present?
        logger.error('No transaction id returned from the MCM message bus')
        @result[:success] = false
        @result[:message] = I18n.t('mortgages.new.upload.error_html', email: collateral_operations_email, phone: collateral_operations_phone_number).html_safe
      else
        mcu_params = params['mortgage_collateral_update']
        @mcu_type = mcu_params['mcu_type']
        @pledge_type = mcu_params['pledge_type'].titlecase
        @program_type = mcu_params["program_type_#{mcu_params['mcu_type']}"].upcase
        uploaded_file = mcu_params['file']
        server_info = Rails.cache.fetch(CacheConfiguration.key(:mcu_server_info), 
                                        expires_in: CacheConfiguration.expiry(:mcu_server_info)) do
          member_balances.mcu_server_info
        end
        unless server_info.present?
          logger.error('No server info returned from the MCM message bus')
          @result[:success] = false
          @result[:message] = I18n.t('mortgages.new.upload.error_html', email: collateral_operations_email, phone: collateral_operations_phone_number).html_safe
        else
          archive_dir = server_info['archiveDir']
          remote_filename = "#{@pledge_type}_#{@transaction_id}_#{uploaded_file.original_filename.gsub(' ', '_')}"
          remote_path_fragment = "#{archive_dir}/MCU/#{current_member_id}"
          remote_path = ""
          if Rails.env.production?
            begin
              now = Time.zone.now
              Net::SFTP.start(server_info['hostname'], 
                              server_info['svcAccountUsername'],
                              password: server_info['svcAccountPassword']) do |sftp|
                sftp.mkdir(remote_path_fragment)
                remote_path_fragment = "#{remote_path_fragment}/#{now.year}"
                sftp.mkdir(remote_path_fragment)
                remote_path_fragment = "#{remote_path_fragment}/#{now.month}"
                sftp.mkdir(remote_path_fragment)
                remote_path = "#{remote_path_fragment}/#{remote_filename}"
                sftp.upload!(uploaded_file.path, remote_path)
              end
            rescue Exception => e
              logger.error("Failed to SFTP #{uploaded_file.path} to #{remote_path}. Reason: #{e.message}")
              @result[:success] = false
              @result[:message] = I18n.t('mortgages.new.upload.error_html', email: collateral_operations_email, phone: collateral_operations_phone_number).html_safe
              return
            end
          end
          @result = member_balances.mcu_upload_file(@transaction_id,
                                                    @mcu_type,
                                                    @program_type, 
                                                    current_user.username,
                                                    remote_path,
                                                    archive_dir)
          unless @result[:success]
            logger.error("MCU upload failed. Reason: #{@result[:message]}")
            @result[:message] = I18n.t('mortgages.new.upload.error_html', email: collateral_operations_email, phone: collateral_operations_phone_number).html_safe
          end
        end
      end
    end
  end

  private

  def translated_mcu_transaction(transaction)
    if transaction
      transaction[:translated_mcuType] = MCU_TYPE_MAPPING[transaction[:mcuType].downcase] if transaction[:mcuType]
      transaction[:translated_pledge_type] = PLEDGE_TYPE_MAPPING[transaction[:pledge_type]] if transaction[:pledge_type]
      transaction[:translated_program_type] = PROGRAM_TYPE_MAPPING[transaction[:program_type]] if transaction[:program_type]
      transaction[:translated_status] = STATUS_MAPPING[transaction[:status]] if transaction[:status]
      transaction[:error_percentage] = ((transaction[:numberOfErrors].to_f / transaction[:numberOfLoans].to_f) * 100 if transaction[:numberOfLoans])
      transaction.with_indifferent_access
    end
  end
end