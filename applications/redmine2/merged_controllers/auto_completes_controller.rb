class AutoCompletesController < ApplicationController
  before_action :find_project
  def issues
    @issues = []
    q = (params[:q] || params[:term]).to_s.strip
    status = params[:status].to_s
    issue_id = params[:issue_id].to_s
    if q.present?
      scope = Issue.cross_project_scope(@project, params[:scope]).visible
      if status.present?
        scope = scope.open(status == 'o')
      end
      if issue_id.present?
        scope = scope.where.not(:id => issue_id.to_i)
      end
      if q.match(/\A#?(\d+)\z/)
        @issues << scope.find_by_id($1.to_i)
      end
      @issues += scope.like(q).order(:id => :desc).limit(10).to_a
      @issues.compact!
    end
    render :layout => false
  end
 raw @issues.map {|issue| {
      'id' => issue.id,
      'label' => "#{issue.tracker} ##{issue.id}: #{issue.subject.to_s.truncate(60)}",
      'value' => issue.id
      }
    }.to_json
  private
  def find_project
    if params[:project_id].present?
      @project = Project.find(params[:project_id])
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
