require 'libusb'

module LibCX320
  class DeviceSimu
    def self.devices
      2.times.map do |idx|
        new(idx)
      end
    end

    def initialize(devidx)
      @devidx = devidx
      @buffers = [{}, {}]
    end

    def close
    end

    def send_inquiry
      "x" * 60
    end

    def log(text)
      puts text
    end
    private :log

    def ready?
      log "ready?"
    end

    def rezero_unit
      log "rezero_unit"
    end

    def get_current_card_position
      [0].pack("C") * 8
    end

    def image_out(layer, data, buffer)
      @buffers[buffer][layer] = data
    end

    def print(color, buffer, async)
      log "print(#{color}, #{buffer}, #{async})"

      if @buffer[buffer][1] && @buffer[buffer][2] && @buffer[buffer][3]
        pic = Magick::Image.new(1036, 664)
        pic.import_pixels(0, 0, 1036, 664, "R", @buffer[buffer][1])
        pic.import_pixels(0, 0, 1036, 664, "G", @buffer[buffer][2])
        pic.import_pixels(0, 0, 1036, 664, "B", @buffer[buffer][3])
        pic.display
      end
      if @buffer[buffer][0]
        pic = Magick::Image.new(1036, 664)
        %w[R G B].each do |color|
          pic.import_pixels(0, 0, 1036, 664, color, @buffer[buffer][0])
        end
        pic.display
      end
    end

    def load_card(pos, flip, adjusted, async)
      log "load_move_card(#{pos}, #{flip}, #{adjusted}, #{async})"
    end

    def move_card(pos, flip, adjusted, async)
      log "load_move_card(#{pos}, #{flip}, #{adjusted}, #{async})"
    end

    def retransfer_and_eject(async)
      log "load_move_card(#{async})"
    end

    def retransfer_and_turn(async)
      log "load_move_card(#{async})"
    end

    def write_mag(format, len, data)
      log "write_mag(#{format}, #{len}, #{data.inspect})"
    end

    def read_mag(format, len)
      "x" * len
    end

    def ic_control(type, action)
      log "write_mag(#{type}, #{action})"
    end
  end
end
