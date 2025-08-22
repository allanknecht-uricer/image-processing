# app/services/image_processor.rb
require "chunky_png"
require "stringio"

class ImageProcessor
  def initialize(path_a, path_b = nil)
    @a = ::UniversalMatrixService.new(path_a).call # <-- note o :: aqui
    @b = ::UniversalMatrixService.new(path_b).call if path_b # <-- e aqui
  end

  # Ajuste em A: soma por canal com clamp 0..255
  # args: { r:, g:, b:, alpha: }
  # retorna StringIO PNG
  def adjust_a(r:, g:, b:, alpha:)
    w = @a[:width]; h = @a[:height]
    out = ChunkyPNG::Image.new(w, h, ChunkyPNG::Color::TRANSPARENT)

    h.times do |y|
      w.times do |x|
        ar, ag, ab, aa = @a[:matrix][y][x]
        nr = clamp8(ar + r)
        ng = clamp8(ag + g)
        nb = clamp8(ab + b)
        na = clamp8(aa + alpha)
        out[x,y] = ChunkyPNG::Color.rgba(nr, ng, nb, na)
      end
    end

    to_io(out)
  end

  # Ajuste em B: soma por canal com clamp 0..255
  # args: { g: }  (neste projeto só o canal G é ajustado)
  # retorna StringIO PNG
  def adjust_b(g:)
    raise "Imagem B não foi enviada" unless @b
    w = @b[:width]; h = @b[:height]
    out = ChunkyPNG::Image.new(w, h, ChunkyPNG::Color::TRANSPARENT)

    h.times do |y|
      w.times do |x|
        br, bg, bb, ba = @b[:matrix][y][x]
        nr = clamp8(br + 0)
        ng = clamp8(bg + g)
        nb = clamp8(bb + 0)
        na = clamp8(ba + 0)
        out[x,y] = ChunkyPNG::Color.rgba(nr, ng, nb, na)
      end
    end

    to_io(out)
  end

  # Mix A⇄B
  # op: "add" | "sub" | "blend"
  # alpha_a/b: 0..100 (usado no blend)
  def mix(op:, alpha_a:, alpha_b:)
    raise "Imagem B não foi enviada" unless @b
    w = [@a[:width], @b[:width]].min
    h = [@a[:height], @b[:height]].min

    out = ChunkyPNG::Image.new(w, h, ChunkyPNG::Color::TRANSPARENT)

    aa = alpha_a.to_f / 100.0
    ab = alpha_b.to_f / 100.0

    h.times do |y|
      w.times do |x|
        ar, ag, abA, aaA = @a[:matrix][y][x]
        br, bg, bbB, aaB = @b[:matrix][y][x]

        r,g,b,a =
          case op
          when "add"
            [ clamp8(ar + br), clamp8(ag + bg), clamp8(abA + bbB), clamp8(aaA + aaB) ]
          when "sub"
            [ clamp8(ar - br), clamp8(ag - bg), clamp8(abA - bbB), clamp8(aaA - aaB) ]
          when "blend"
            [
              clamp8(ar * aa + br * ab),
              clamp8(ag * aa + bg * ab),
              clamp8(abA* aa + bbB* ab),
              clamp8(aaA* aa + aaB* ab),
            ]
          else
            raise "Operação inválida: #{op}"
          end

        out[x,y] = ChunkyPNG::Color.rgba(r,g,b,a)
      end
    end

    to_io(out)
  end

  private

  def clamp8(v)
    v = v.round
    return 0   if v < 0
    return 255 if v > 255
    v
  end

  def to_io(png_img)
    io = StringIO.new
    png_img.write(io)
    io.rewind
    io
  end
end
