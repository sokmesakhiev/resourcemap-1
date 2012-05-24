require 'treetop_dependencies'
require 'digest'

class MessagingController < ApplicationController
  helper_method :save_message
  protect_from_forgery :except => :index
	skip_before_filter :authenticate, :only => :getLayerMessaging

  USER_NAME, PASSWORD = 'iLab', '1c4989610bce6c4879c01bb65a45ad43'

  # POST /messaging
  def index
    #raise HttpVerbNotSupported.new unless request.post?
    
    message = save_message

    begin
      message.process! params
    rescue => err
      message.reply = err.message
    ensure
    if (message.reply != "Invalid command")
      message[:layer_id] = get_layer_id(params[:body])
    end
      message.save
      render :text => message.reply, :content_type => "text/plain"
    end
  end

  def authenticate
    authenticate_or_request_with_http_basic 'Dynamic Resource Map - HTTP' do |username, password|
      USER_NAME == username && PASSWORD == Digest::MD5.hexdigest(password)
    end
  end

  def get_layer_id(bodyMsg)
    if (bodyMsg[5] == "q")
      layerId = Message.getLayerId(bodyMsg, 7)
    elsif (bodyMsg[5] == "u")
      resourceCode = Message.getLayerId(bodyMsg, 7)
      resource = Resource.find_by_id_with_prefix(resourceCode)  
      layerId = resource.layer_id
    end
    return layerId
  end

  def save_message
    Message.create!(:guid => params[:guid], :from => params[:from], :body => params[:body]) do |m|
      m.country = params[:country]
      m.carrier = params[:carrier]
      m.channel = params[:channel]
      m.application = params[:application]
      m.to = params[:to]
    end
  end

  def getLayerMessaging
    layerMessaging = Message.generateLayerMessagingByLayerId(params["layerId"], params["year"])
    render :json => layerMessaging
  end

end
