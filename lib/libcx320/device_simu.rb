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
      @card_pos = nil
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
      [@card_pos ? 0x04 : 0x00, 0, 0, 0, 0, 0, 0, @card_pos].pack("CCCCCCCC")
    end

    def image_out(layer, data, buffer)
      @buffers[buffer][layer] = data
    end

    def print(color, buffer, async)
      log "print(#{color}, #{buffer}, #{async})"

      if @buffers[buffer][1] && @buffers[buffer][2] && @buffers[buffer][3]
        pic = Magick::Image.new(1036, 664)
        pic.import_pixels(0, 0, 1036, 664, "R", @buffers[buffer][1])
        pic.import_pixels(0, 0, 1036, 664, "G", @buffers[buffer][2])
        pic.import_pixels(0, 0, 1036, 664, "B", @buffers[buffer][3])
        pic.display
      end
      if @buffers[buffer][0]
        pic = Magick::Image.new(1036, 664)
        %w[R G B].each do |color|
          pic.import_pixels(0, 0, 1036, 664, color, @buffers[buffer][0])
        end
        pic.display
      end
    end

    def load_card(pos, flip, adjusted, async)
      log "load_move_card(#{pos}, #{flip}, #{adjusted}, #{async})"
      raise CommandSequenceError, "card is already loaded" if @card_pos
      @card_pos = pos
    end

    def move_card(pos, flip, adjusted, async)
      log "load_move_card(#{pos}, #{flip}, #{adjusted}, #{async})"
      raise CommandSequenceError, "no card loaded" unless @card_pos
      @card_pos = pos
    end

    def retransfer_and_eject(async)
      log "load_move_card(#{async})"
      raise CommandSequenceError, "card is not in position retransfer" if @card_pos != 0
      @card_pos = nil
    end

    def retransfer_and_turn(async)
      log "load_move_card(#{async})"
      raise CommandSequenceError, "card is not in position retransfer" if @card_pos != 0
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

    def mode_sense(page, len)
      log "mode_sense(#{page}, #{len})"
      0.upto(len-1).map{|i| [1].pack("C") }.join
    end

    def mode_select(page, data)
      log "mode_select(#{page}, #{data.unpack("H*")[0]})"
    end

    def log_sense(page, len)
      log "log_sense(#{page}, #{len})"
      0.upto(len-1).map{|i| [1].pack("C") }.join
    end

    def log_select
      log "log_select()"
    end
  end
end
