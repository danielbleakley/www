city_constraint = Proc.new do |req|
  city = req.params[:city]
  city.blank? || city.match(/^(#{AlumniClient.new.city_slugs.join("|")})$/i)
end

Rails.application.routes.draw do

  # config/static_routes.yml
  STATIC_ROUTES.each do |template, locale_paths|
    locale_paths.each do |locale, page|
      get page => "pages##{template}", template: template, locale: locale.to_sym, as: "#{template}_#{locale.to_s.underscore}".to_sym
    end
  end

  # Redirects
  get 'premiere', to: redirect('programme')
  get 'marseille', to: redirect('aix-marseille')
  get 'sp', to: redirect('pt-BR/sao-paulo')
  get 'bh', to: redirect('pt-BR/belo-horizonte')
  get 'en', to: redirect('/')
  get 'stories', to: redirect('alumni')
  get 'fr/stories', to: redirect('fr/alumni')
  get 'en/*path', to: redirect { |path_params, req| path_params[:path] }

  get 'ondemand/*path', to: redirect { |path_params, req| "https://ondemand.lewagon.org/#{req.fullpath.gsub("/ondemand/", "")}" }
  get 'codingstationparis', to: redirect('https://www.meetup.com/fr-FR/Le-Wagon-Paris-Coding-Station')

  {
    'davidverbustel' => 'david-joins-efounders',
    'oliviergodement' => 'olivier-joined-stripe-as-user-ops-lead',
    'amontcoudiol' => 'adrien-and-max-reinvent-tv',
    'olixier' => 'seeding-one-million-with-kudoz',
    'aliceclv' => 'alice-joins-save-as-backend-dev'
  }.each do |github_nickname, new_slug|
    ['', 'fr/'].each do |locale|
      get "#{locale.to_s.underscore}stories/#{github_nickname}", to: redirect("#{locale.to_s.underscore}stories/#{new_slug}")
    end
  end

  constraints(city_constraint) do
    get "apply/(:city)" => "applies#new", locale: :en, as: :apply_en
    get "postuler/(:city)" => "applies#new", locale: :fr, as: :apply_fr
    get "candidatar/(:city)" => "applies#new", locale: :"pt-BR", as: :apply_pt_br
    post "apply/(:city)" => "applies#create", as: :apply
  end

  get "blog/rss", to: 'posts#rss', defaults: { format: :xml }

  get "hec", to: 'applies#new_hec', as: :new_hec_apply
  post "hec", to: 'applies#create_hec', as: :hec_apply, locale: :fr

  scope "(:locale)", locale: /fr|pt-BR/ do
    root to: "pages#home"
    get "faq", to: "pages#show", template: "faq", as: :faq
    get "jobs", to: "pages#show", template: "jobs", as: :jobs
    get "stack", to: "pages#stack", template: "stack", as: :stack
    get "employers", to: "pages#employers", template: "employers", as: :employers
    get "tv", to: "pages#tv", template: "tv", as: :tv
    get "alumni" => "students#index", as: :alumni
    get "blog", to: 'posts#index', as: :blog
    get "blog/:slug", to: 'posts#show', as: :post

    constraints(city_constraint) do
      get ":city" => "cities#show", as: :city
    end
    resources :projects, only: [:show]
    resources :stories, only: [:show]
    resources :students, only: [:show]
  end

  resources :subscribes, only: :create

  # API
  resource :cache, only: :destroy

  # SEO
  get 'robots', to: 'pages#robots'

  # Old
  get 'wagon_bar', to: redirect('/fr')

  match "*path", to: "application#render_404", via: :all
end

# Create helper for static_routes
Rails.application.routes.url_helpers.module_eval do
  STATIC_ROUTES.each do |route, _|
    define_method "#{route}_path".to_sym do |args = {}|
      locale = args[:locale] || :fr
      self.send(:"#{route}_#{locale.to_s.underscore}_path")
    end

    define_method "#{route}_url".to_sym do |args = {}|
      locale = args[:locale] || :fr
      self.send(:"#{route}_#{locale.to_s.underscore}_url")
    end
  end
end
