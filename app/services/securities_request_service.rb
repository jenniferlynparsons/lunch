class SecuritiesRequestService < MAPIService
  attr_reader :member_id

  def initialize(member_id, request)
    super(request)
    @member_id = member_id
    raise ArgumentError.new('`member_id` must not be blank') if member_id.blank?
  end

  def authorized
    requests = get_json(:authorized, "/member/#{member_id}/securities/requests", status: :authorized, settle_start_date: Time.zone.today - 7.days)
    process_securities_requests(requests)
  end

  def awaiting_authorization
    requests = get_json(:awaiting_authorization, "/member/#{member_id}/securities/requests", status: :awaiting_authorization)
    process_securities_requests(requests)
  end

  def submit_release_for_authorization(securities_release_request, user)
    body = {
      broker_instructions: securities_release_request.broker_instructions,
      delivery_instructions: securities_release_request.delivery_instructions,
      securities: securities_release_request.securities,
      user: {
        username: user.username,
        full_name: user.display_name,
        session_id: request.session.id
      }
    }
    post_hash(:securities_submit_release_for_authorization, "#{member_id}/securities/release", body.to_json)
  end

  private

  def process_securities_requests(requests)
    requests.try(:collect) do |request|
      fix_date(request.with_indifferent_access, [:authorized_date, :settle_date, :submitted_date])
    end
  end

end