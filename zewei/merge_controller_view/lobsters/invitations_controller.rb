class InvitationsController < ApplicationController
  before_filter :require_logged_in_user,
    :except => [ :build, :create_by_request, :confirm_email ]

  def build
    if Rails.application.allow_invitation_requests?
      @invitation_request = InvitationRequest.new
    else
      flash[:error] = "Public invitation requests are not allowed."
      return redirect_to "/login"
    end
 form_for @invitation_request,
  :url => create_invitation_by_request_path do |f| 
 f.label :name, "Name:" 
 f.text_field :name, :size => 30 
 f.label :email, "E-mail Address:" 
 f.text_field :email, :size => 30 
 f.label :memo, "URL:" 
 f.text_field :memo, :size => 30 
 submit_tag "Request Invitation" 
 end 

  end

  def index
    @invitation_requests = InvitationRequest.where(:is_verified => true)
 if @user.is_moderator? 
 end 
 bit = 0 
 @invitation_requests.each do |ir| 
 bit 
 ir.created_at.strftime("%Y-%m-%d %H:%M:%S") 
 ir.name 
 if @user.is_moderator? 
 ir.email 
 end 
 raw ir.markeddown_memo 
 form_tag send_invitation_for_request_path do 
 hidden_field_tag "code", ir.code 
 submit_tag "Send Invitation", :data => { :confirm => "Are " <<
        "you sure you want to invite this person and remove this request?" } 
 end 
 if @user.is_moderator? 
 form_tag delete_invitation_request_path do 
 hidden_field_tag "code", ir.code 
 submit_tag "Delete", :data => { :confirm => "Are you sure " <<
            "you want to delete this request?" } 
 end 
 end 
 bit = (bit == 1 ? 0 : 1) 
 end 
 if @invitation_requests.count == 0 
 @user.is_moderator?? 5 : 4 
 end 

  end

  def confirm_email
    if !(ir = InvitationRequest.where(:code => params[:code].to_s).first)
      flash[:error] = "Invalid or expired invitation request"
      return redirect_to "/invitations/request"
    end

    ir.is_verified = true
    ir.save!

    flash[:success] = "Your invitation request has been validated and " <<
      "will now be shown to other logged-in users."
    return redirect_to "/invitations/request"
  end

  def create
    i = Invitation.new
    i.user_id = @user.id
    i.email = params[:email]
    i.memo = params[:memo]

    begin
      i.save!
      i.send_email
      flash[:success] = "Successfully e-mailed invitation to " <<
        params[:email].to_s << "."
    rescue
      flash[:error] = "Could not send invitation, verify the e-mail " <<
        "address is valid."
    end

    if params[:return_home]
      return redirect_to "/"
    else
      return redirect_to "/settings"
    end
  end

  def create_by_request
    if Rails.application.allow_invitation_requests?
      @invitation_request = InvitationRequest.new(
        params.require(:invitation_request).permit(:name, :email, :memo))

      @invitation_request.ip_address = request.remote_ip

      if @invitation_request.save
        flash[:success] = "You have been e-mailed a confirmation to " <<
          params[:invitation_request][:email].to_s << "."
        return redirect_to "/invitations/request"
      else
        render :action => :build
      end
    else
      return redirect_to "/login"
    end
  end

  def send_for_request
    if !(ir = InvitationRequest.where(:code => params[:code].to_s).first)
      flash[:error] = "Invalid or expired invitation request"
      return redirect_to "/invitations"
    end

    i = Invitation.new
    i.user_id = @user.id
    i.email = ir.email

    i.save!
    i.send_email
    ir.destroy!
    flash[:success] = "Successfully e-mailed invitation to " <<
      ir.name.to_s << "."

    return redirect_to "/invitations"
  end

  def delete_request
    if !@user.is_moderator?
      return redirect_to "/invitations"
    end

    if !(ir = InvitationRequest.where(:code => params[:code].to_s).first)
      flash[:error] = "Invalid or expired invitation request"
      return redirect_to "/invitations"
    end

    ir.destroy!
    flash[:success] = "Successfully deleted invitation request from " <<
      ir.name.to_s << "."

    return redirect_to "/invitations"
  end
end
