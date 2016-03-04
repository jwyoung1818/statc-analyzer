# encoding: utf-8
class BoardsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_referer_or_authenticity_token, only: [:create]
  before_action :authenticate_account!, only: :create
  after_action :expire_cache, only: [:create]
  caches_page :show, if: Proc.new { |c| c.request.format.xml? }
  respond_to :html, :xml

  def show
    @boards = Board.all(Board.free)
    respond_with(@boards)
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 h1 "Tribune" 
 link_to "Version XML", "/board/index.xml" 
  board = boards.build 
 Push.private_key(board.meta) 
 if current_account && current_account.can_post_on_board? 
  form_tag "/board", class: 'chat' do 
 hidden_field :board, :object_type, value: form.object_type 
 hidden_field :board, :object_id, value: form.object_id 
 text_field :board, :message, value: '', size: 80, autocomplete: 'off', required: 'required', spellcheck: 'true', autofocus: (form.object_type == Board.free) 
 submit_tag 'Envoyer', class: "submit_board" 
 end 
 
 end 
  board.id 
 board.user_agent 
 board.created_at.iso8601 
 norloge(board, box) 
 board.user_link 
 board.message 
 
 

end

  end

  def create
    board = Board.new board_params
    board.user = current_account.user
    enforce_create_permission(board)
    board.user_agent = request.user_agent
    board.save
    board.news.tap {|news| news.node.read_by current_account.id if news }
    respond_to do |wants|
      wants.html { redirect_to :back rescue redirect_to root_url }
      wants.js   { render nothing: true }
      wants.xml  { render nothing: true }
    end
  end

protected

  def board_params
    params.require(:board).permit(:object_type, :object_id, :message)
  end

  def expire_cache
    expire_page action: :show, format: :xml
  end
end
