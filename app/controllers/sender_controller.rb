require 'fcm'
class SenderController < ApplicationController
  before_action :authenticate_user!
  before_action :set_token, only: [:show,:edit,:update,:destroy]
  def index
    @tokens =  Token.all.paginate(:page => params[:page],:per_page => 10).order("created_at ASC")
  end
  def show
  end
  def destroy
    @token.destroy
    respond_to do |format|
      format.html {redirect_to sender_index_path, notice: "The token was destroyed"}
      format.json { head :no_content }
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
        format.json { render :show, status: :created, location: @token }
      else
        format.html { render :new }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end
  def edit

  end
  def update
    respond_to do |format|
      if @token.update(tokens_params)
        format.html { redirect_to sender_index_path, notice: 'The token was updated' }
        format.json { render :show, status: :ok, location: @token }
      else
        format.html { render :edit }
        format.json { render json: @token.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    def set_token
      @token = Token.find(params[:id])
    end
    def tokens_params
      params.require(:token).permit(:token_id)
    end
end
