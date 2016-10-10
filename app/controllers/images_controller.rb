class ImagesController < ApplicationController
  before_action :set_image, only: [:show, :edit, :update, :destroy]

  # GET /images
  # GET /images.json
  def index
    @images = Image.all.paginate(:page => params[:page],:per_page=> 10).order("created_at ASC")
  end

  # GET /images/1
  # GET /images/1.json
  def show
  end

  # GET /images/new
  def new
    @image = Image.new
  end

  # GET /images/1/edit
  def edit
  end

  # POST /images
  # POST /images.json
  def create
    @imageTemp = Image.where("token_id = ? AND route = ?",params[:sender_id],params[:image][:route]).first
    if @imageTemp == nil
      @image = Image.new(image_params)
      @token = Token.find(params[:sender_id])
      respond_to do |format|
        if @image.save
          @token.images << @image
          @token.save
          format.html { redirect_to @image, notice: 'Image was successfully created.' }
          format.json { render @image, status: 201 }
        else
          format.html { render :new }
          format.json { render json: @image.errors, status: :unprocessable_entity }
        end
      end
    else
      if @imageTemp.update(image_params)
        format.html { redirect_to @imageTemp, notice: 'Image was successfully updated.' }
        format.json { render :show, status: 201}
      else
        format.html { render :edit }
        format.json { rendroer json: @imageTemp.errors, status: :unprocessable_entity }
      end
    end
  end
  def createAndSend
    if params.key?("file") && params.key?("token_id") && params.key("route")
      token =  Token.find(params[:token_id])
      imageTemp = Image.where("token_id = ? AND route = ?",token.id,params[:route])
      if imageTemp == nil
        image = Image.new(image:params[:file],route: params[:route])
        if image.save
          token.images << image
          token.save
          imageThumbUrl = image.image.thumb.url
          imageUrl = image.image.url
          sendMessageFromClient(params[:token_id],params[:route],imageTumbUrl,imageUrl)

        else
          render json: {errors: "There was an error"}, status: 500
        end
      else
        imageTemp.file = params[:file]
        if imageTemp.save
          imageThumbUrl = imageTemp.image.thumb.url
          imageUrl = imageTemp.image.url
          sendMessageFromClient(params[:token_id],params[:route],imageTumbUrl,imageUrl)
        else
          render json: {errors: "There was an error"}, status: 500
        end
      end
    else
      render json: {errors: "Some parameters are missing"}, status: 400
    end

  end

  # PATCH/PUT /images/1
  # PATCH/PUT /images/1.json
  def update
    respond_to do |format|
      if @image.update(image_params)
        format.html { redirect_to @image, notice: 'Image was successfully updated.' }
        format.json { render :show, status: 201}
      else
        format.html { render :edit }
        format.json { render json: @image.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /images/1
  # DELETE /images/1.json
  def destroy
    @image.destroy
    respond_to do |format|
      format.html { redirect_to images_url, notice: 'Image was successfully destroyed.' }
      format.json { render json: @image, status: 204 }
    end
  end
  def sendScreenshot
    response = nil
    topic = params[:route]
    token = Token.find(params[:token_id])
    token_id = token.token_id
    image = Image.where("token_id = ? AND route = ?",token.id,topic).first
    title = "Screenshot"
    subtitle = "The person with id #{token_id} has just send your location"
    body = "This person is following the route with id #{topic}"
    imageThumbUrl = image.image.thumb.url
    imageUrl = image.image.url
    with_retries(:max_tries=>20,:base_sleep_seconds=>0.1,:max_sleep_seconds=>20) do |attempt|
      if attempt == 20
        redirect_to sender_index_path, notice: 'There was a problem when we tried to send the screenshot'
      else
        reponse ||= sendMessageToTopicWithImage(topic,body,title,subtitle,imageUrl,imageThumbUrl)
        redirect_to sender_index_path, notice: 'The message was sent succesfully'
      end
    end
  end

  private
    def sendMessageFromClient(token_id,topic,imageTumbUrl,imageUrl)
      title = "Screenshot"
      subtitle = "The person with id #{token_id} has just send your location"
      body = "This person is following the route with id #{topic}"
      with_retries(:max_tries=>20,:base_sleep_seconds=>0.1,:max_sleep_seconds=>20) do |attempt|
        if attempt == 20
          render json: {success: "We have sent the message"}, status: 200
        else
          reponse ||= sendMessageToTopicWithImage(topic,body,title,subtitle,imageUrl,imageThumbUrl)
          render json: {errors: "We can't send the message"}, status: 500
        end
      end
    end
    def sendMessageToTopicWithImage(topic,body,title,subtitle,imageUrl,imageThumbUrl)
      fcm = FCM.new(Rails.application.secrets.fcm_key)
      options = {notification: {body: body,title:title,sound:"default",subtitle:subtitle,click_action:"sokolscreenshot"},data:{image_url: imageUrl,image_thumb_url: imageThumbUrl},priority:"high",content_available:true,time_to_live:2419200}
      response = fcm.send_to_topic(topic,options)
      p "#{response}"
      unless response[:status_code] >= 200 && response[:status_code] < 300
        raise StandardError,"Error"
      end
    end
    # Use callbacks to share common setup or constraints between actions.
    def set_image
      @image = Image.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def image_params
      params.require(:image).permit(:image,:route,:token_id)
    end
end
