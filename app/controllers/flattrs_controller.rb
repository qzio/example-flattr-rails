class FlattrsController < ApplicationController

  before_filter :ensure_authenticated , :except => [:new,:start_over]

  def start_over
    session[:flattr] = nil
    redirect_to new_flattr_path
  end

  def new
    if is_callback?
      c = get_flattr_client
      @user_info = c.user_info
      @user_things = c.user_things
      session[:flattr][:access_token] = @access_token if @access_token
    else
      c = get_flattr_client
      @request_token = c.get_request_token
      @authorize_url = c.authorize_url
      session[:flattr] = {:request_token => @request_token}
    end
  end



  def ensure_authenticated
    if session[:flattr] && session[:flattr][:access_token]
      true
    else
      redirect_to new_flattr_path
    end
  end

  def things
    render :text => "a couple of things"
  end

  def thing
  end

  def is_callback?
    (params[:oauth_token] && params[:oauth_verifier])
  end

  helper_method :is_callback?

  protected

  def get_flattr_client
    flattr_params = {
        :key => FLATTR_CONFIG[:key],
        :secret => FLATTR_CONFIG[:secret],
        :site => FLATTR_CONFIG[:site],
        :authorize_path => '/oauth/authenticate',
        :callback_url => new_flattr_url,
        :debug => true
    }
    if session[:flattr]
      flattr_params[:request_token] = session[:flattr][:request_token] if session[:flattr][:request_token]
      flattr_params[:access_token] = session[:flattr][:access_token] if session[:flattr][:access_token]
      flattr_params[:oauth_verifier] = params[:oauth_verifier] if params[:oauth_verifier]
    end
    @client ||= FlattrRest::Base.new(flattr_params)
  end
end
