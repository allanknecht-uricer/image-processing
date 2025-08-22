class ImagesController < ApplicationController
  def create
    @use_b = params[:use_b] == "1"
    a_file = params[:image_a]
    b_file = params[:image_b] if @use_b

    unless a_file.present?
      flash.now[:alert] = "Envie a Imagem A."
      return respond_to do |format|
        format.turbo_stream { render :create } # mostra flash sem navegar
        format.html { render "home/index", status: :unprocessable_entity }
      end
    end

    unless image_file?(a_file)
      flash.now[:alert] = "A Imagem A precisa ser uma imagem."
      return respond_to do |format|
        format.turbo_stream { render :create }
        format.html { render "home/index", status: :unprocessable_entity }
      end
    end

    if @use_b && b_file.present? && !image_file?(b_file)
      flash.now[:alert] = "A Imagem B precisa ser uma imagem."
      return respond_to do |format|
        format.turbo_stream { render :create }
        format.html { render "home/index", status: :unprocessable_entity }
      end
    end

    processor = ImageProcessor.new(a_file.tempfile.path, b_file&.tempfile&.path)

    io =
      if @use_b && params[:op_ab].present?
        processor.mix(
          op:      params[:op_ab],
          alpha_a: params[:alpha_a].to_i,
          alpha_b: params[:alpha_b].to_i
        )
      elsif @use_b && params[:add_b].present?
        processor.adjust_b(g: params[:add_b].to_i)
      else
        processor.adjust_a(
          r:     params[:a_add_r].to_i,
          g:     params[:a_add_g].to_i,
          b:     params[:a_add_b].to_i,
          alpha: params[:a_add_alpha].to_i
        )
      end

    blob = ActiveStorage::Blob.create_and_upload!(
      io: io, filename: "resultado.png", content_type: "image/png"
    )
    @result_url = url_for(blob)

    # (opcional) matrizes
    begin
      @mat_a = UniversalMatrixService.new(a_file.tempfile.path).call
      if @use_b && b_file.present?
        @mat_b = UniversalMatrixService.new(b_file.tempfile.path).call
      end
    rescue
    end

    respond_to do |format|
      format.turbo_stream { render :create } # usa create.turbo_stream.erb
      format.html { render "home/index", status: :ok } # fallback
    end
  rescue => e
    Rails.logger.error(e.full_message)
    flash.now[:alert] = "Falha no processamento: #{e.message}"
    respond_to do |format|
      format.turbo_stream { render :create }
      format.html { render "home/index", status: :internal_server_error }
    end
  end

  private

  def image_file?(uploaded)
    uploaded.content_type.to_s.start_with?("image/")
  end
end
