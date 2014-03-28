require 'sinatra/base'
require 'sinatra/cookies'
require 'meda'
require 'meda/collector/connection'

module Meda
  module Collector

    class App < Sinatra::Base

      set :public_folder, 'static'

      helpers Sinatra::Cookies

      get '/' do
        "Meda version #{Meda::VERSION}"
      end

      # Serve any files from the /static directory

      get '/static/:file' do
        path = File.join(settings.public_folder, params[:file])
        send_file path
      end

      # Identify

      get '/identify.json' do
        user = settings.connection.identify(params)
        set_profile_id_in_cookie(user.profile_id)
        user.marshal_dump.to_json
      end

      get '/identify.gif' do
        user = settings.connection.identify(params)
        set_profile_id_in_cookie(user.profile_id)
        respond_with_pixel
      end

      # Profile

      get '/profile.json' do
        get_profile_id_from_cookie
        settings.connection.profile(params)
        respond_with_ok
      end

      get '/profile.gif' do
        get_profile_id_from_cookie
        settings.connection.profile(params)
        respond_with_pixel
      end

      # Accept google analytics __utm.gif formatted hits

      get '/__utm.gif' do
        get_profile_id_from_cookie
        if params[:utmt] == 'event'
          settings.connection.track(event_params_from_utm)
        else
          settings.connection.page(page_params_from_utm)
        end
        respond_with_pixel
      end

      # Page

      get '/page.json' do
        get_profile_id_from_cookie
        settings.connection.page(params)
        respond_with_ok
      end

      get '/page.gif' do
        get_profile_id_from_cookie
        settings.connection.page(params.merge(request_environment))
        respond_with_pixel
      end

      # Track

      get '/track.json' do
        get_profile_id_from_cookie
        settings.connection.track(params)
        respond_with_ok
      end

      get '/track.gif' do
        get_profile_id_from_cookie
        settings.connection.track(params)
        respond_with_pixel
      end

      # Config

      configure :production, :development do
        set :connection, Meda::Collector::Connection.new
      end

      protected

      def respond_with_ok
        {"status" => "ok"}.to_json
      end

      def respond_with_pixel
        img_path = File.expand_path('../../../../assets/images/1x1.gif', __FILE__)
        send_file(open(img_path), :type => 'image/gif', :disposition => 'inline')
      end

      def set_profile_id_in_cookie(id)
        cookies[:'_meda_profile_id'] = id
      end

      def get_profile_id_from_cookie
        params[:profile_id] ||= cookies[:'_meda_profile_id']
      end

      #

      def request_environment
        {
          :user_ip => request.env['REMOTE_ADDR'],
          :referrer => request.env['HTTP_REFERER'],
          :user_agent => request.env['HTTP_USER_AGENT']
        }
      end

      def page_params_from_utm
        {
          :profile_id => cookies[:'_meda_profile_id'],
          :name => params[:utmdt] || params[:utmp],
          :hostname => params[:utmhn],
          :referrer => params[:utmr] || request.env['HTTP_REFERER'],
          :user_ip => params[:utmip] || request.env['REMOTE_ADDR'],
          :user_agent => request.env['HTTP_USER_AGENT'],
          :path => params[:utmp],
          :title => params[:utmdt],
          :user_language => params[:utmul],
          :screen_depth => params[:utmsc],
          :screen_resolution => params[:utmsr]
        }
      end

      def event_params_from_utm
        parsed_utme = params[:utme].match(/\d\((.+)\*(.+)\*(.+)\*(.+)\)/) # '5(object*action*label*value)'
        {
          :profile_id => cookies[:'_meda_profile_id'],
          :name => params[:utme],
          :category => parsed_utme[1],
          :action => parsed_utme[2],
          :label => parsed_utme[3],
          :value => parsed_utme[4],
          :hostname => params[:utmhn],
          :referrer => params[:utmr] || request.env['HTTP_REFERER'],
          :user_ip => params[:utmip] || request.env['REMOTE_ADDR'],
          :user_agent => request.env['HTTP_USER_AGENT'],
          :user_language => params[:utmul],
          :screen_depth => params[:utmsc],
          :screen_resolution => params[:utmsr]
        }
      end

    end

  end
end

