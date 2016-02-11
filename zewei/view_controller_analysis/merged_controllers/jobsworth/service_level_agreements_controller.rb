class ServiceLevelAgreementsController < ApplicationController
  before_filter :authorize_user_is_admin

  def index
    @service_level_agreements = ServiceLevelAgreement.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @service_level_agreements }
    end
 t("service_level_agreements.list_sla") 
 t("service_level_agreements.service") 
 t("service_level_agreements.customer") 
 t("service_level_agreements.billable") 
 t("service_level_agreements.company") 
 @service_level_agreements.each do |service_level_agreement| 
 service_level_agreement.service_id 
 service_level_agreement.customer_id 
 service_level_agreement.billable 
 service_level_agreement.company_id 
 link_to t("button.show"), service_level_agreement 
 link_to t("button.edit"), edit_service_level_agreement_path(service_level_agreement) 
 link_to t("button.destroy"), service_level_agreement, confirm: t("shared.are_you_sure"), method: :delete 
 end 
 link_to t("service_level_agreements.new_sla"), new_service_level_agreement_path 

  end

  def show
    @service_level_agreement = current_user.company.service_level_agreements.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @service_level_agreement }
    end
 notice 
 t("service_level_agreements.service") 
 @service_level_agreement.service_id 
 t("service_level_agreements.customer") 
 @service_level_agreement.customer_id 
 t("service_level_agreements.billable") 
 @service_level_agreement.billable 
 t("service_level_agreements.company") 
 @service_level_agreement.company_id 
 link_to t("button.edit"), edit_service_level_agreement_path(@service_level_agreement) 
 link_to t("button.back"), service_level_agreements_path 

  end

  def new
    @service_level_agreement = ServiceLevelAgreement.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @service_level_agreement }
    end
 t("service_level_agreements.new_sla") 
  form_for(@service_level_agreement) do |f| 
  if object.errors.any? 
 t("shared.form_errors") 
 object.errors.full_messages.each do |error_message| 
 error_message 
 end 
 end 
 
 end 
 
 link_to t("button.back"), service_level_agreements_path 

  end

  def edit
    @service_level_agreement = current_user.company.service_level_agreements.find(params[:id])
 t("service_level_agreements.edit_sla") 
  form_for(@service_level_agreement) do |f| 
  if object.errors.any? 
 t("shared.form_errors") 
 object.errors.full_messages.each do |error_message| 
 error_message 
 end 
 end 
 
 end 
 
 link_to t("button.show"), @service_level_agreement 
 link_to t("button.back"), service_level_agreements_path 

  end

  def create
    @service_level_agreement = ServiceLevelAgreement.new(params[:service_level_agreement])
    @service_level_agreement.company_id = current_user.company_id

    if ServiceLevelAgreement.where(:service_id => @service_level_agreement.service_id).where(:customer_id => @service_level_agreement.customer_id).count > 0
      return render :json => {
        success: false,
        message: t('flash.error.pair_already_added',
                   first: @service_level_agreement.service.name,
                   second: @service_level_agreement.customer.name)
      }
    end

    if @service_level_agreement.save
      html = render_to_string :partial => "service_level_agreements/service_level_agreement", :locals => {:service_level_agreement => @service_level_agreement}
      render :json => {:success => true, :html => html}
    else
      render :json => {:success => false, :message => @service_level_agreement.errors.full_messages.join(". ") }
    end
  end

  # PUT /service_level_agreements/1
  # PUT /service_level_agreements/1.json
  def update
    @service_level_agreement = current_user.company.service_level_agreements.find(params[:id])

    if @service_level_agreement.update_attributes(params[:service_level_agreement])
      render :json => {:success => true}
    else
      render :json => {:success => false, :message => @service_level_agreement.errors.full_messages.join(". ") }
    end
  end

  # DELETE /service_level_agreements/1
  # DELETE /service_level_agreements/1.json
  def destroy
    @service_level_agreement = current_user.company.service_level_agreements.find(params[:id])
    @service_level_agreement.destroy

    render :json => {:success => true}
  end
end
