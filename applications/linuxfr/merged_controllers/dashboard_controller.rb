# encoding: utf-8
class DashboardController < ApplicationController
  before_action :authenticate_account!
  before_action :reset_notifications, only: [:index]

  def index
    @self_answer = params[:self] == "1"
    @comments = current_user.comments.on_dashboard.limit(30)
    @comments = @comments.where(answered_to_self: false) unless @self_answer
    @posts    = Node.where(user_id: current_user.id).on_dashboard(Post).limit(10)
    @trackers = Node.where(user_id: current_user.id).on_dashboard(Tracker).limit(10)
    @news     = News.where(author_email: current_account.email).candidate
    @drafts   = News.where(author_email: current_account.email).draft
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
  @title.join(' - ').html_safe 
 if current_stylesheet 
 stylesheet_link_tag current_stylesheet, media: nil 
 elsif current_account 
 stylesheet_link_tag current_account.stylesheet_url, media: nil 
 else 
 stylesheet_link_tag 'application', media: nil 
 end 
 if @google_plus 
 end 
 if @author 
 end 
 if @dont_index 
 end 
 @feeds.each do |link,title| 
 auto_discovery_link_tag :atom, link, { title: title } 
 end 
 
  ("active" if controller_name == "home") 
 link_to "Accueil", '/', title: "Page d'accueil du site, personnalisable" 
 ("active" if controller_name == "news" || controller_name == "sections") 
 link_to "Dpches", '/news', title: "Actualits, vnements et autres nouveauts" 
 ("active" if controller_name == "forums" || controller_name == "posts") 
 link_to "Forums", '/forums', title: "Questions/rponses, petites annonces" 
 ("active" if controller_name == "polls") 
 link_to "Sondages", '/sondages', title: "Sondages proposes aux visiteurs du site" 
 ("active" if controller_name == "wiki_pages" || controller_name == "wiki_versions") 
 link_to "Wiki", '/wiki', title: "Pages wiki" 
 ("active" if controller_name == "trackers") 
 link_to "Suivi", '/suivi', title: "Suivi des suggestions et des bugs du site" 
 form_tag '/recherche', method: :get do 
 submit_tag "Rechercher", name: nil, id: "search_submit", title: "Lancer la recherche sur le site" 
 end 
 
  logo 
 account_signed_in? ? link_to(current_account.login, current_account.user) : "Se connecter" 
 link_to "Proposer un contenu", '/proposer-un-contenu' 
 if account_signed_in? 
 if current_account.has_answers? 
 image_tag "/images/icones/chat.svg", alt: "Nouveaux !", title: "Vous avez reu des rponses  vos commentaires", width: "16px" 
 end 
 link_to "Mon tableau de bord", '/tableau-de-bord' 
 link_to "Mes contenus taggs", '/tags' 
 link_to "Les contenus que j'ai lus", '/readings' 
 link_to "Modifier mes prfrences", '/compte/modifier' 
 link_to "Changer de style", '/stylesheet/modifier' 
 button_to "Se dconnecter", '/compte/deconnexion', method: :post, id: "logout" 
 else 
  @account ||= Account.new 
 form_for @account, url: '/compte/connexion', html: { id: "#{dom_id @account}#{id_suffix}" }, authenticity_token: false do |f| 
 f.label "login#{id_suffix}", "Identifiant" 
 f.text_field :login, id: "account_login#{id_suffix}", required: "required", placeholder: "Identifiant", size: 20 
 f.label "password#{id_suffix}", "Mot de passe" 
 f.password_field :password, id: "account_password#{id_suffix}", required: "required", placeholder: "Mot de passe", size: 20 
 f.check_box :remember_me, id: "account_remember_me#{id_suffix}" 
 f.label "remember_me#{id_suffix}", "Connexion automatique" 
 f.submit "Se connecter", id: "account_submit#{id_suffix}" 
 end 
 
 end 
 if current_account 
  link_to "Rdaction", '/redaction' 
 link_to "Tribune de rdaction", '/redaction' 
 list_of News.draft.sorted.limit(10) do |news| 
 if news.node.board_status(current_account) == :new_board 
 image_tag "/images/icones/chat.svg", alt: "Nouveaux !", title: "Il y a de l'activit sur cette dpche", width: "16px" 
 end 
 link_to news.title, [:redaction, news] 
 end 
 link_to "(...)", "/redaction#news" 
 
 end 
 yield :column 
 
 [:alert, :notice].each do |type| 
 if flash[type] 
 end 
 end 
  h1 "Votre tableau de bord" 
  if @drafts.empty? 
 else 
 @drafts.each do |news| 
 news.section.title 
 link_to news.title, [:redaction, news] 
 l news.created_at 
 end 
 end 
 
  if @news.empty? 
 else 
 @news.each do |news| 
 news.section.title 
 if current_account.amr? 
 link_to news.title, [:moderation, news] 
 else 
 news.title 
 end 
 l news.node.created_at 
 end 
 end 
 
  if @comments.empty? 
 else 
 if @self_answer 
 link_to "Ne pas inclure les rponses  mes commentaires", self: nil 
 else 
 link_to "Inclure les rponses  mes commentaires", self: "1" 
 end 
 @comments.each do |comment| 
 next if comment.node.nil? 
 answer = comment.last_answer 
 link_to comment.title, path_for_content(comment.node.content) + "#comment-#{comment.id}" 
 comment.created_at.to_s(:posted) 
 comment.bound_score 
 if answer && !answer.read_by?(current_account) 
 image_tag "/images/icones/comment.png", alt: "Nouveaux commentaires !", class: "thread-new-comments" 
 end 
 comment.nb_answers 
 answer ? answer.created_at.to_s(:posted) : "&nbsp;".html_safe 
 end 
 end 
 
  if @posts.empty? 
 else 
 @posts.each do |node| 
 post = node.content 
 post.forum.title 
 link_to post.title, [post.forum, post] 
 node.score 
 node.comments.count 
 post.created_at.to_s(:posted) 
 end 
 end 
 
  if @trackers.empty? 
 else 
 @trackers.each do |node| 
 tracker = node.content 
 tracker.state 
 tracker.category.title 
 link_to tracker.title, tracker 
 tracker.state_name 
 node.score 
 node.comments.count 
 tracker.created_at.to_s(:posted) 
 end 
 end 
 
 link_to "Revenir en haut de page", '#top', class: 'scroll' 
 cache "layouts/footer", expires_in: 1.minute do 
  @last_comments.each do |comment| 
 link_to comment.title, path_for_content(comment.node.content) + "#comment-#{comment.id}" 
 end 
 @popular_tags.each do |tag| 
 link_to tag.name, "/tags/#{tag.name}/public" 
 end 
 @friend_sites.each do |site| 
 link_to site.title, site.url 
 end 
 link_to "Mentions lgales", '/mentions_legales' 
 link_to "Faire un don", '/faire_un_don' 
 link_to "Team LinuxFr.org", '/team' 
 link_to "Informations sur le site", '/informations' 
 link_to "Aide / Foire aux questions", '/aide' 
 link_to "Rgles de modration", '/regles_de_moderation' 
 link_to "Statistiques", '/statistiques' 
 link_to "API pour les dveloppeurs", '/developpeur' 
 link_to "Code source du site", '/code_source_du_site' 
 link_to "Plan du site", '/plan' 
 
 end 
 javascript_include_tag "application" 

end

  end

  def answers
    render json: { node_ids: current_account.answers_node_id }
  end

protected

  def reset_notifications
    current_account.reset_answers_notifications
  end

end
