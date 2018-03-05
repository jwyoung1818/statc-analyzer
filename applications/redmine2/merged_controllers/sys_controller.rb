class SysController < ActionController::Base
  before_action :check_enabled
  def projects
    p = Project.active.has_module(:repository).
          order("#{Project.table_name}.identifier").preload(:repository).to_a
    render :json => p.to_json(
                       :only => [:id, :identifier, :name, :is_public, :status],
                       :include => {:repository => {:only => [:id, :url]}}
                     )
  end
  def create_project_repository
    project = Project.find(params[:id])
    if project.repository
      head 409
    else
      logger.info "Repository for #{project.name} was reported to be created by #{request.remote_ip}."
      repository = Repository.factory(params[:vendor])
      repository.safe_attributes = params[:repository]
      repository.project = project
      if repository.save
        render :json => {repository.class.name.underscore.gsub('/', '-') => {:id => repository.id, :url => repository.url}}, :status => 201
      else
        head 422
      end
    end
  end
  def fetch_changesets
    projects = []
    scope = Project.active.has_module(:repository)
    if params[:id]
      project = nil
      if params[:id].to_s =~ /^\d*$/
        project = scope.find(params[:id])
      else
        project = scope.find_by_identifier(params[:id])
      end
      raise ActiveRecord::RecordNotFound unless project
      projects << project
    else
      projects = scope.to_a
    end
    projects.each do |project|
      project.repositories.each do |repository|
        repository.fetch_changesets
      end
    end
    head 200
  rescue ActiveRecord::RecordNotFound
    head 404
  end
  protected
  def check_enabled
    User.current = nil
    unless Setting.sys_api_enabled? && params[:key].to_s == Setting.sys_api_key
      render :plain => 'Access denied. Repository management WS is disabled or key is invalid.', :status => 403
      return false
    end
  end
end
