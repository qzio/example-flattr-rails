class FlattrsController < ApplicationController

  before_filter :ensure_authenticated , :except => [:new,:start_over]

  before_filter :set_flattr_client, :except => [:start_over]

  def start_over
    session[:flattr] = nil
    redirect_to new_flattr_path
  end

  def new
    logger.info "have access: #{have_access?}"
    if is_callback?
      begin
        access_token = @client.access_token
        logger.info "access_token: #{access_token.inspect}"
        logger.info "i want to save the access token which is #{access_token.inspect.to_s.size} chars"
        session[:flattr][:access_token_params] = @client.access_token_params
        @user_info = @client.user_info
        @user_things = @client.user_things
      rescue
        logger.info "unable to get the access token: #{$!}"
        redirect_to :action => :start_over
      end
    else
      begin
        @request_token = @client.request_token
        @authorize_url = @client.authorize_url
        session[:flattr] = {:request_token => @request_token}
      rescue
        logger.info"recovering from #{$!}..."
        if session[:flattr]
          redirect_to :action => :start_over
        else
          logger.info "session[:flattrr] is nil.. mega fail."
          render :text => 'unable to get request token, something wrong with your credentials/settings?'
        end
      end
    end
  end

  def me
    @user_info = @client.user_info
    @things = @client.user_things
  end

  def users
    @user_info = @client.user_info params[:id]
    @things = @client.things :user_id => params[:id]
    render :user
  end

  def things
    if (params[:id])
      @things = []
      thing = @client.things(:id => params[:id])
      @things << thing if thing
    elsif params[:user_id]
      logger.info"will try on user_id"
      @things = @client.things(:user_id => params[:user_id])
    elsif params[:q]
      logger.info"will with query: #{params[:q]}"
      @things = @client.things(:q => params[:q])
    else
      @things = @client.user_things
    end

    render(:text => "unable to find the thing(s)") if @things.blank?
  end

  def new_thing
    @languages = {}
    @client.languages.each do |lang|
      @languages[lang.language_id] = lang.name
    end
    @categories = {}
    @client.categories.each do |category|
      @categories[category.category_id] = category.name
    end
  end

  def create_thing
    @client.submit_thing params[:thing]
    redirect_to :action => 'me'
  end

  def languages
    @models = @client.languages
    render 'simple'
  end

  def categories
    @models = @client.categories
    render 'simple'
  end

  protected

  def is_callback?
    (params[:oauth_token] && params[:oauth_verifier])
  end
  helper_method :is_callback?

  def have_access?
    return (session[:flattr] && session[:flattr][:access_token_params])
  end
  helper_method :have_access?


  def ensure_authenticated
    redirect_to(new_flattr_path) unless have_access?
  end

  def set_flattr_client
    flattr_params = {
        :key => FLATTR_CONFIG[:key],
        :secret => FLATTR_CONFIG[:secret],
        :site => FLATTR_CONFIG[:site],
        :authorize_path => '/oauth/authenticate',
        :callback_url => new_flattr_url,
        :logger => Rails.logger,
        :debug => true
    }
    if session[:flattr]
      if session[:flattr][:access_token_params]
        logger.info 'using the session access token'
        flattr_params[:access_token_params] = session[:flattr][:access_token_params]
      else
        logger.info "no access token in the session"
        flattr_params[:request_token] = session[:flattr][:request_token] if session[:flattr][:request_token]
        flattr_params[:oauth_verifier] = params[:oauth_verifier] if params[:oauth_verifier]
      end
    end
    @client ||= FlattrRest::Base.new(flattr_params)
  end

end
