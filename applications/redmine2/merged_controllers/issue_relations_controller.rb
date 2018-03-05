class IssueRelationsController < ApplicationController
  helper :issues
  before_action :find_issue, :authorize, :only => [:index, :create]
  before_action :find_relation, :only => [:show, :destroy]
  accept_api_auth :index, :show, :create, :destroy
  def index
    @relations = @issue.relations
    respond_to do |format|
      format.html { head 200 }
      format.api
    end
  end
  def show
    raise Unauthorized unless @relation.visible?
    respond_to do |format|
      format.html { head 200 }
      format.api
    end
  end
  def create
    @relation = IssueRelation.new
    @relation.issue_from = @issue
    @relation.safe_attributes = params[:relation]
    @relation.init_journals(User.current)
    begin
      saved = @relation.save
    rescue ActiveRecord::RecordNotUnique
      saved = false
      @relation.errors.add :base, :taken
    end
    respond_to do |format|
      format.html { redirect_to issue_path(@issue) }
      format.js {
        @relations = @issue.reload.relations.select {|r| r.other_issue(@issue) && r.other_issue(@issue).visible? }
      }
      format.api {
        if saved
          render :action => 'show', :status => :created, :location => relation_url(@relation)
        else
          render_validation_errors(@relation)
        end
      }
    end
  end
  def destroy
    raise Unauthorized unless @relation.deletable?
    @relation.init_journals(User.current)
    @relation.destroy
    respond_to do |format|
      format.html { redirect_to issue_path(@relation.issue_from) }
      format.js
      format.api  { render_api_ok }
    end
  end
  private
  def find_issue
    @issue = Issue.find(params[:issue_id])
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  def find_relation
    @relation = IssueRelation.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
