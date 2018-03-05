class MailHandlerController < ActionController::Base
  before_action :check_credential
  def new
  end
 form_tag({}, :multipart => true, :action => 'post') do 
 hidden_field_tag 'key', params[:key] 
 text_area_tag 'email', '', :style => 'width:95%; height:400px;' 
 select_tag 'unknown_user', options_for_select(['', 'ignore', 'accept', 'create']) 
 text_field_tag 'default_group' 
 check_box_tag 'no_account_notice', 1 
 check_box_tag 'no_notification', 1 
 check_box_tag 'no_permission_check', 1 
 text_field_tag 'issue[project]' 
 text_field_tag 'issue[status]' 
 text_field_tag 'issue[tracker]' 
 text_field_tag 'issue[category]' 
 text_field_tag 'issue[priority]' 
 text_field_tag 'issue[assigned_to]' 
 text_field_tag 'issue[fixed_version]' 
 check_box_tag 'issue[private]', 1 
 text_field_tag 'allow_override' 
 submit_tag 'Submit Email' 
 end 
  def index
    options = params.dup
    email = options.delete(:email)
    if MailHandler.receive(email, options)
      head :created
    else
      head :unprocessable_entity
    end
  end
  private
  def check_credential
    User.current = nil
    unless Setting.mail_handler_api_enabled? && params[:key].to_s == Setting.mail_handler_api_key
      render :plain => 'Access denied. Incoming emails WS is disabled or key is invalid.', :status => 403
    end
  end
end
