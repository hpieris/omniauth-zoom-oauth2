require 'omniauth/strategies/oauth2'
require 'omniauth/zoom_oauth2/api'

module OmniAuth
  module Strategies
    class ZoomOauth2 < OmniAuth::Strategies::OAuth2
      option :name, 'zoom_oauth2'

      option :client_options, {
        token_url: "/oauth/token",
        authorize_url: "/oauth/authorize",
        site: "https://zoom.us"
      }

      uid { info['id'] }

      info do
        unless @info
          api = OmniAuth::ZoomOauth2::API.new(token)
          @info = api.get("/users/me")
        end

        @info
      end

      def user_info
        info
      end

      def token
        access_token.token
      end

      credentials do
        _credentials = {'token' => access_token.token}

        if access_token.expires? && access_token.refresh_token
          _credentials = _credentials.merge('refresh_token' => access_token.refresh_token)
        end

        if access_token.expires?
          _credentials = _credentials.merge('expires_at' => access_token.expires_at)
        end

        _credentials.merge!('expires' => access_token.expires?)
      end

      extra do
        { 'scope' => access_token.params['scope'] }
      end

      private 

      def callback_url
        full_host + script_name + callback_path
      end

      def full_host #https://github.com/omniauth/omniauth/issues/101
        uri = URI.parse(request.url)
        uri.path = ''
        uri.query = nil
        if Rails.env.production?
          uri.port = (uri.scheme == 'https' ? 443 : 80)
        else
          uri.port = 3000
        end
        uri.to_s
      end
    end
  end
end
