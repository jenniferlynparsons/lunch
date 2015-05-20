class SettingsController < ApplicationController

  before_action do
    @sidebar_options = [
        [t("settings.password.title"), '#'],
        [t("settings.quick_advance.title"), '#'],
        [t("settings.quick_report.title"), '#'],
        [t("settings.two_factor.title"), settings_two_factor_path],
        [t("settings.email.title"), settings_path]
    ]
    @sidebar_options.unshift([t("settings.account.title"), settings_users_path]) if policy(:access_manager).show?
  end

  before_action only: [:users] do
    authorize :access_manager, :show?
  end

  def index
    @email_options = ['reports'] + CorporateCommunication::VALID_CATEGORIES
  end

  # POST
  def save
    # set cookies
    cookie_data = params[:cookies] || {}
    cookie_data.each do |key, value|
      cookies[key.to_sym] = value
    end
    # TODO add status once we have some concept of actually saving data
    now = Time.now
    json_response = {timestamp: now.strftime('%a %d %b %Y, %I:%M %p'), status: 200}.to_json
    render json: json_response
  end

  # GET
  def users
    @users = MembersService.new(request).users(current_member_id).try(:sort_by, &:display_name) || []
    @roles = {}
    @actions = {}
    @users.each do |user|
      roles = user.roles.collect do |role|
        if role == User::Roles::ACCESS_MANAGER
          t('settings.account.roles.access_manager')
        elsif role == User::Roles::AUTHORIZED_SIGNER
          t('settings.account.roles.authorized_signer')
        end
      end
      roles.compact!
      @roles[user.id] = roles.present? ? roles : [t('settings.account.roles.user')]
      is_current_user = user.id == current_user.id
      @actions[user.id] = {
        locked: user.locked?,
        locked_disabled: is_current_user,
        reset_disabled: is_current_user
      }
    end
  end

  # GET
  def two_factor
    
  end

  # POST
  def reset_pin
    securid = SecurIDService.new(current_user.username)
    begin
      securid.authenticate(params[:securid_pin], params[:securid_token])
      status = securid.status
    rescue SecurIDService::InvalidPin => e
      status = 'invalid_pin'
    rescue SecurIDService::InvalidToken => e
      status = 'invalid_token'
    end
    if securid.change_pin?
      begin
        status = 'success' if securid.change_pin(params[:securid_new_pin])
      rescue SecurIDService::InvalidPin => e
        status = 'invalid_new_pin'
      end
    end
    render json: {status: status}
  end

  def resynchronize
    securid = SecurIDService.new(current_user.username)
    begin
      securid.authenticate(params[:securid_pin], params[:securid_token])
      status = securid.status
    rescue SecurIDService::InvalidPin => e
      status = 'invalid_pin'
    rescue SecurIDService::InvalidToken => e
      status = 'invalid_token'
    end
    if securid.resynchronize?
      begin
        securid.resynchronize(params[:securid_pin], params[:securid_next_token])
        status = 'success' if securid.authenticated? 
      rescue SecurIDService::InvalidPin => e
        status = 'invalid_pin'
      rescue SecurIDService::InvalidToken => e
        status = 'invalid_next_token'
      end
    end
    render json: {status: status}
  end

end