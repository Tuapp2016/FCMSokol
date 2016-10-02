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
        format.json { render json: @imageTemp.errors, status: :unprocessable_entity }
      end
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
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_image
      @image = Image.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def image_params
      params.require(:image).permit(:image,:route,:token_id)
    end
end
