# app/services/universal_matrix_service.rb
require "mini_magick"

class UniversalMatrixService
  # Uso:
  #   out = UniversalMatrixService.new(path).call
  # Retorno:
  #   {
  #     width: Integer,
  #     height: Integer,
  #     mode: :grayscale | :graya | :rgb | :rgba | :unknown,
  #     binary_like: true/false,     # preto/branco (0/255) após expandir
  #     matrix: Array[h][w][4]       # cada pixel: [r,g,b,a] em 0..255
  #   }

  def initialize(path)
    @path = path
  end

  def call
    img = MiniMagick::Image.open(@path)
    begin
      img.colorspace "sRGB"
    rescue
    end

    w, h = img.width, img.height
    pixels = img.get_pixels # => [h][w][C] (C = 1 a 4)

    mode = detect_mode(pixels)
    rgba =
      case mode
      when :grayscale then process_grayscale(pixels)   # 1 canal
      when :graya     then process_graya(pixels)       # 2 canais (G+A)
      when :rgb       then process_rgb(pixels)         # 3 canais
      when :rgba      then process_rgba(pixels)        # 4 canais
      else                 process_unknown(pixels)     # fallback
      end

    {
      width:  w,
      height: h,
      mode:   mode,
      binary_like: binary_like?(rgba),
      matrix: rgba
    }
  end

  private

  def detect_mode(pixels)
    sample = pixels[0][0] rescue nil
    return :unknown unless sample.is_a?(Array)

    case sample.length
    when 1 then :grayscale
    when 2 then :graya
    when 3 then :rgb
    when 4 then :rgba
    else        :unknown
    end
  end

  def process_grayscale(pix)
    h = pix.size
    w = pix.first.size
    Array.new(h) do |y|
      row = pix[y]
      Array.new(w) do |x|
        g = to8(row[x][0])
        [g, g, g, 255]
      end
    end
  end

  def process_graya(pix)
    h = pix.size
    w = pix.first.size
    Array.new(h) do |y|
      row = pix[y]
      Array.new(w) do |x|
        g = to8(row[x][0])
        a = to8(row[x][1])
        [g, g, g, a]
      end
    end
  end

  def process_rgb(pix)
    h = pix.size
    w = pix.first.size
    Array.new(h) do |y|
      row = pix[y]
      Array.new(w) do |x|
        r, g, b = row[x]
        [to8(r), to8(g), to8(b), 255]
      end
    end
  end

  def process_rgba(pix)
    h = pix.size
    w = pix.first.size
    Array.new(h) do |y|
      row = pix[y]
      Array.new(w) do |x|
        r, g, b, a = row[x]
        [to8(r), to8(g), to8(b), to8(a)]
      end
    end
  end

  def to8(v)
    v = v.to_i
    v = (v / 257.0).round if v > 255
    v = 0   if v < 0
    v = 255 if v > 255
    v
  end

  def binary_like?(rgba)
    h = rgba.size
    w = rgba.first.size
    step_y = [1, h / 64].max
    step_x = [1, w / 64].max

    rgba.each_with_index do |row, y|
      next unless (y % step_y).zero?
      row.each_with_index do |px, x|
        next unless (x % step_x).zero?
        r, g, b, a = px
        return false unless [r, g, b, a].all? { |c| c == 0 || c == 255 }
      end
    end
    true
  end
end
