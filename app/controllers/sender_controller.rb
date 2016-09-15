require 'fcm'
require "retries"
class SenderController < ApplicationController
  before_action :authenticate_user!, only:[:destroy]
  before_action :set_token, only: [:show,:edit,:update,:destroy]
  def index
    @tokens =  Token.all.paginate(:page => params[:page],:per_page => 10).order("created_at ASC")
    @page = 1
    @page ||= params[:page]
  end
  def show
  end
  def destroy
    @token.destroy
    respond_to do |format|
      format.html {redirect_to sender_index_path, notice: "The token was destroyed"}
      format.json {render json: @token, status: 204}
    end
  end
  def new
    @token = Token.new
  end
  def create
    @token = Token.new(tokens_params)
    respond_to do |format|
      if @token.save
        format.html{redirect_to sender_index_path,notice:"The token was created"}
        format.json {render json: @token, status: 201}
      else
        format.html { render :new }
        format.json { render json: @token.errors, status: :unprocessable_entity }
      end
    end
  end
  def edit
  end
  def update
    respond_to do |format|
      if @token.update(tokens_params)
        format.html { redirect_to sender_index_path, notice: 'The token was updated' }
        format.json {render json: @token, status: 201}
      else
        format.html { render :edit }
        format.json { render json: @token.errors, status: :unprocessable_entity }
      end
    end
  end
  def sender
    render 'sendTopic'
  end
  def sendTopic
    respond_to do |format|
      if params.key?("topic")
        response =  nil
        body = params["body"]
        title = params["title"]
        body ||= "The route " + params["topic"] + " just crossed a checkpoint"
        title ||= "Checkpoint notification"

        with_retries(:max_tries=>20,:base_sleep_seconds=>0.1,:max_sleep_seconds=>2.0) do |attempt|
          if attempt == 20
            format.html {redirect_to sender_index_path, notice: 'There was an error'}
            format.json {render json: {error: "There was an error"}, status:500}
          else
            response ||= sendMessageToTopic(params["topic"],body,title)
            format.html {redirect_to sender_index_path, notice: 'The message was sent succesfully'}
            format.json {render json: {success:"The message was sent succesfully"}, status:200}
          end
        end
      else
        format.html {redirect_to sender_index_path, notice: "We can\'t send the message"}
        format.json {render json: {error: "We can\'t send the message"}, status:400}
      end
    end
  end
  def senderAll
    tokens = Token.all
    respond_to do |format|
      response = nil
      body = params["body"]
      title = params["title"]
      body ||= "The route just crossed a checkpoint"
      title ||= "Checkpoint notification"
      with_retries(:max_tries=> 20,:base_sleep_seconds =>0.1, :max_sleep_seconds => 2.0)  do |attempt|
        if attempt == 20
          format.html {redirect_to sender_index_path, notice: 'There was an error'}
          format.json {render json: {error: "There was an error"}, status:500}
        else
          response ||= sendMessage(tokens,body,title)
          format.html {redirect_to sender_index_path, notice: 'The message was sent succesfully'}
          format.json {render json: {success: "The message was sent succesfully"}, status:200}
        end
      end
    end

  end
  def senderByPage
    tokens = Token.all.paginate(:page => params[:page],:per_page => 10).order("created_at ASC")
    respond_to do |format|
      response = nil
      body = params["body"]
      title = params["title"]
      body ||= "The route just crossed a checkpoint"
      title ||= "Checkpoint notification"
      with_retries(:max_tries=> 20,:base_sleep_seconds =>0.1, :max_sleep_seconds => 2.0) do |attempt|
        if attempt == 20
          format.html {redirect_to sender_index_path, notice: 'The message was sent succesfully'}
          format.json {render json: {error:"There was an error"}, status:500}
        else
          response ||= sendMessage(tokens,body,title)
          format.html {redirect_to sender_index_path, notice: 'The message was sent succesfully'}
          format.json {render json: {success:"The message was sent succesfully"}, status:200}
        end
      end
    end
  end

  private
    def sendMessageToTopic(topic,body,title)
      fcm = FCM.new(Rails.application.secrets.fcm_key)
      options = {notification: {body: body,title:title},priority:"high",content_available:true,time_to_live:2419200}
      response = fcm.send_to_topic(topic,options)
      p "#{response}"
      unless response[:status_code] >= 200 && response[:status_code] < 300
        raise StandardError,"Error"
      end
    end
    def sendMessage(tokens,body,title)
      fcm = FCM.new(Rails.application.secrets.fcm_key)
      registration_ids = []
      tokens.each do |t|
        registration_ids << t.token_id
      end
      options = {notification: {body: body,title:title},priority:"high",content_available:true,time_to_live:2419200}
      response = fcm.send(registration_ids,options)
      if response[:status_code] >= 200 && response[:status_code] < 300
        deleteInvalidTokens(response,registration_ids)
      else
        raise StandardError,"Error"
      end
      response
    end
    def deleteInvalidTokens(response,registration_ids )
      body = response[:body]
      parsed_json = JSON(body)
      results = parsed_json["results"]
      results.each_with_index do |val,index|
        #resultValue = parsed_json = JSON(val)
        if val.key?("error")
          if val["error"] == "InvalidRegistration" || val["error"] == "NotRegistered"
            token_id = registration_ids[index]
            t = Token.where("token_id = ?",token_id).first
            t.destroy
          end
        end
      end
    end
    def set_token
      @token = Token.find(params[:id])
    end
    def tokens_params
      params.require(:token).permit(:token_id)
    end
end
