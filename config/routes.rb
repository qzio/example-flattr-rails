FlattrSample::Application.routes.draw do
  resource :flattr do
    member do
      get :things
      get :thing
      get :start_over
    end
  end
  root :to => "flattrs#new"
end
