require 'rubygems'
require 'bundler'

Bundler.require

class BlackMailbox < Sinatra::Base
  register Sinatra::ConfigFile

  config_file 'settings.yml'

  helpers do
    def flash
      @flash ||= {}
    end

    def email
      @email ||= settings.try(:email).to_s
    end

    def gpg_key
      @gpg_key ||= settings.try(:gpg_key).to_s
    end

    def check_installation!
      if email.empty? || gpg_key.empty?
        flash[:danger] = 'Bad installation. Please provide email and gpg key.'
        status 503
        return false
      end
      true
    end
  end

  get '/' do
    check_installation!
    slim :app
  end

  post '/' do
    unless check_installation!
      return slim :app
    end

    message = params[:message].to_s

    if message.empty?
      flash[:danger] = 'Please provide message'
      status 422
      return slim :app
    end

    mail = Mail.new(
      to: email,
      from: 'blackbox@localhost',
      subject: 'Message from Black Mailbox',
      body: message,
      gpg: { encrypt: true, keys: { email => gpg_key } }
    )

    begin
      if mail.deliver
        flash[:success] = 'Message was sent'
      else
        raise StandardError, 'Message was not sent'
      end
    rescue => e
      flash[:danger] = e
      status 403
      return slim :app
    end
    slim :app
  end
end
