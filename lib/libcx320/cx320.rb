
module LibCX320
  class CX320
    attr_reader :dev

    def initialize(dev)
      @dev = dev
    end

    def self.devices(dev_type)
      dev_type.devices.map do |dev|
        self.new(dev)
      end
    end

    def close
      @dev.close
    end

    def ready?
      @dev.ready?
    end

    def rezero_unit
      @dev.rezero_unit
    end

    def get_current_card_position
      resp = @dev.get_current_card_position

      # PU (Position Unknown) - Byte 0 Bit 3
      # 0: The card is in the printer unit.
      # 1: No card in the printer unit
      #
      # Note: Printer reports PU = 1 even if any card is in the card hopper. Printer generates
      # Check Condition if the card is being transported.
      #
      # Byte 7
      # Position: Card position in the printer unit.
      # 0: At Retransfer Position 1:At Contact IC Encoder 2: At No-Contact IC encoder
      # 3: At MAG encoder Greater than 3: Reserved
      #
      # Byte 1 Bit 0
      # Load Mode: The way to load the card
      # 0: From the card tray
      # 1: From the right side card entrance

      card_position = { pu: nil, position: nil, load_mode: nil}
      card_position[:pu] = resp.getbyte(0) & 0x4 != 0 ? :no_card_in_printer : :card_in_printer

      card_position[:position] = case resp.getbyte(7)
        when 0 then :retransfer
        when 1 then :contact
        when 2 then :contactless
        when 3 then :magnetstripe
        else raise "Invalid card_position: #{resp.getbyte(7).inspect}!"
      end

      card_position[:load_mode] = resp.getbyte(0) & 0x1 != 0 ? :right_side : :card_tray

      card_position
    end

    ImageLayer2Code = {
      K: 0,
      C: 1,
      M: 2,
      Y: 3,
      UV: 4,
      PeelOff: 5
    }

    def image_out(layer, data, buffer=0)
      buffer = Buffer2Code[buffer] || buffer
      layer = ImageLayer2Code[layer] || layer

      @dev.image_out(layer, data, buffer)
    end

    # Notice: As K LUT is used internally, K must not be specified.
    LutLayer2Code = {
      K: 0,
      C: 2,
      M: 4,
      Y: 6
    }
    def lut=(layer, lut)
      layer = LutLayer2Code[layer] ? LutLayer2Code[layer] : layer

      data = FFI::MemoryPointer.new :char, 256
      data.write_bytes lut

      check_returncode C.CXCMD_DefineLUT(@slot, @id, data.size, data)
    end

    Buffer2Code = {
      frontside: 0,
      backside: 1,
    }

    PrintColor2Code = {
      YMC: 0b1,
      K: 0b10,
      UV: 0b100,
      PeelOff: 0b1000
    }
    def print(color=[:YMC, :K], buffer=0, async=false)
      buffer = Buffer2Code[buffer] || buffer
      color = color.map{|c| PrintColor2Code[c] }.inject(&:|) if color.kind_of?(Array)
      async = async ? 1 : 0

      @dev.print(color, buffer, async)
    end

    Position2Code = {
      retransfer: 0,
      contact: 1,
      contactless: 2,
      magnetstripe: 3,
      eject: 4
    }
    def load_card(pos=:retransfer, flip=false, adjusted=false, async=false)
      pos = Position2Code[pos] ? Position2Code[pos] : pos
      flip = flip ? 1 : 0
      adjusted = adjusted ? 1 : 0 # This setting is effective only when Destination is NG Card outlet
      async = async ? 1 : 0

      @dev.load_card(pos, flip, adjusted, async)
    end

    def move_card(pos=:retransfer, flip=false, adjusted=false, async=false)
      pos = Position2Code[pos] ? Position2Code[pos] : pos
      flip = flip ? 1 : 0
      adjusted = adjusted ? 1 : 0 # This setting is effective only when Destination is NG Card outlet
      async = async ? 1 : 0

      @dev.move_card(pos, flip, adjusted, async)
    end

    def retransfer_and_eject(async=false)
      async = async ? 1 : 0
      @dev.retransfer_and_eject(async)
    end

    def retransfer_and_turn(async=false)
      async = async ? 1 : 0
      @dev.retransfer_and_turn(async)
    end

    MagFormat = {
      jis2_7bit: [0x07, 69], # 69 charcters at most
      iso1_6bit: [0x16, 76], # 76 charcters at most
      iso1_7bit: [0x17, 69], # 69 charcters at most
      iso2_4bit: [0x24, 37], # 37 charcters at most
      iso3_4bit: [0x34, 104], # 104 charcters at most
      iso3_7bit: [0x37, 69], # 69 charcters at most
    }

    def write_mag(format, data)
      format, len = MagFormat[format] || format
      @dev.write_mag(format, len, data)
    end

    def read_mag(format)
      format, len = MagFormat[format] || format
      @dev.read_mag(format, len)
    end

    IC_Types = {
      contact: 0,
      contactless: 1,
    }

    IC_Actions = {
      contact: 0,
      release: 1,
    }

    def ic_control(type, action)
      type = IC_Types[type] || type
      action = IC_Actions[action] || action
      @dev.ic_control(type, action)
    end

    # Infos & Settings
    # attach_function :CXCMD_ModeSense, [:int, :int, :pointer], :int
    # attach_function :CXCMD_ModeSelect, [:int, :int, :int, :pointer], :int
    # attach_function :CXCMD_LogSense, [:int, :int, :int, :pointer], :int
    # attach_function :CXCMD_LogSelect, [:int, :int], :int
  end

  class CX320_DLL < CX320
    def self.devices(*args)
      super(DeviceDll, *args)
    end
  end

  class CX320_USB < CX320
    def self.devices(*args)
      super(DeviceUsb, *args)
    end
  end

  class CX320_SIMU < CX320
    def self.devices(*args)
      super(DeviceSimu, *args)
    end
  end
end
