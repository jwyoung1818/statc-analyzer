# encoding: UTF-8
class Admin::ForumsController < AdminController
  before_action :find_forum, except: [:index, :new, :create]

  def index
    @forums = Forum.sorted.all
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
  h1 "Les forums" 
 link_to "Crer un forum", new_admin_forum_path 
 if @forums.empty? 
 else 
 @forums.each do |forum| 
 link_to forum.title, forum 
 button_to "&uarr;".html_safe, higher_admin_forum_path(forum) 
 button_to "&darr;".html_safe, lower_admin_forum_path(forum) 
 link_to "Modifier", edit_admin_forum_path(forum) 
 if forum.active? 
 button_to "Archiver", archive_admin_forum_path(forum), data: { confirm: "Archiver le forum ?" }, class: "archive_button" 
 else 
 button_to "R-ouvrir", reopen_admin_forum_path(forum), data: { confirm: "R-ouvrir le forum ?" }, class: "reopen_button" 
 end 
 button_to "Supprimer", [:admin, forum], method: :delete, data: { confirm: "Supprimer le forum ?" }, class: "delete_button" 
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

  def new
    @forum = Forum.new
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
  h1 "Crer un nouveau forum" 
 form_for [:admin, @forum] do |form| 
 render form 
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

  def create
    @forum = Forum.new
    @forum.attributes = params[:forum]
    if @forum.save
      @forum.move_to_bottom
      redirect_to admin_forums_url, notice: "Forum créé"
    else
      flash.now[:alert] = "Impossible d'enregistrer ce forum"
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
  h1 "Crer un nouveau forum" 
 form_for [:admin, @forum] do |form| 
 render form 
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
  end

  def edit
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
  h1 "Modifier un forum" 
 form_for [:admin, @forum] do |form| 
 render form 
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

  def update
    @forum.attributes = params[:forum]
    if @forum.save
      redirect_to admin_forums_url, notice: "Forum modifié"
    else
      flash.now[:alert] = "Impossible d'enregistrer ce forum"
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
  h1 "Modifier un forum" 
 form_for [:admin, @forum] do |form| 
 render form 
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
  end

  def archive
    @forum.archive
    redirect_to admin_forums_url, notice: "Forum archivé"
  end

  def reopen
    @forum.reopen
    redirect_to admin_forums_url, notice: "Forum ré-ouvert"
  end

  def destroy
    @forum.destroy
    redirect_to admin_forums_url, notice: "Forum supprimé"
  end

  def lower
    @forum.move_lower
    redirect_to admin_forums_url
  end

  def higher
    @forum.move_higher
    redirect_to admin_forums_url
  end

protected

  def find_forum
    @forum = Forum.find(params[:id])
  end

end
