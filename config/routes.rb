Rails.application.routes.draw do
  root to: 'page#index'
  post 'contactUS', to: 'page#contactUS'
  devise_scope :user do
    get "/sign_up",  :to => "page#index"
  end
  resources :sender do
    collection do
      post "senderByPage", :senderByPage
      post "senderAll", :senderAll
      post "sendTopic", :sendTopic
      get "sender", :sender
    end
  end
  devise_for :users, :path=> '', :path_names =>{:sign_in => 'signin',:sign_out=>'signout'}
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

end
