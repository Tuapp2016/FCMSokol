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
  def senderAll
    tokens = Token.all
    respond_to do |format|
      response = nil
      with_retries(:max_tries=> 20,:base_sleep_seconds =>0.1, :max_sleep_seconds => 2.0)  do |attempt|
        if attempt == 20
          format.html {redirect_to sender_index_path, notice: 'The message was sent succesfully'}
          format.json {render json: {error: "There was an error"}, status:500}
        else
          response ||= sendMessage(tokens)
          format.html {redirect_to sender_index_path, notice: 'The message was sent succesfully'}
          format.json {render json: {error: "The message was sent succesfully"}, status:200}
        end
      end
    end

  end
  def senderByPage
    tokens = Token.all.paginate(:page => params[:page],:per_page => 10).order("created_at ASC")
    respond_to do |format|
      response = nil
      with_retries(:max_tries=> 20,:base_sleep_seconds =>0.1, :max_sleep_seconds => 2.0) do |attempt|
        if attempt == 20
          format.html {redirect_to sender_index_path, notice: 'The message was sent succesfully'}
          format.json {render json: "There was an error", status:500}
        else
          response ||= sendMessage(tokens)
          format.html {redirect_to sender_index_path, notice: 'The message was sent succesfully'}
          format.json {render json: "The message was sent succesfully", status:200}
        end
      end
    end
  end

  private
    def sendMessage(tokens)
      fcm = FCM.new(Rails.application.secrets.fcm_key)
      registration_ids = []
      tokens.each do |t|
        registration_ids << t.token_id
      end
      options = {notification: {body: "Hola como vas",title:"Notification"},priority:"high",content_available:true}
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
