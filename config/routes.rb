FlattrSample::Application.routes.draw do
  resource :flattr do
    member do
      get :things
      get :start_over
      get :me
      get :categories
      get :languages
    end
    match 'things/:id', :action => 'things'
    match 'things/by_user/:user_id', :action => 'things'
    match 'users/:id', :action => 'users'
    match 'new_thing', :action => 'new_thing'
    post 'create_thing', :action => 'create_thing'
  end
  root :to => "flattrs#new"
end
