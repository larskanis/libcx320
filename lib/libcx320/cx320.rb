require_relative 'c'

module LibCX320
  class CX320
    attr_reader :slot, :id

    def self.find_next(slot: nil, id: nil)
      slot = FFI::MemoryPointer.new :int
      slot.put_int if slot
      id = FFI::MemoryPointer.new :int
      id.put_int if id

      check_returncode C.CXCMD_ScanCX320Next(slot, id)

      new(slot.read_int, id.read_int)
    end

    def self.find_first
      slot = FFI::MemoryPointer.new :int
      id = FFI::MemoryPointer.new :int

      check_returncode C.CXCMD_ScanCX320(slot, id)

      new(slot.read_int, id.read_int)
    end

    def intialize(slot, id)
      @slot = slot
      @id = id
    end


    def connected?
      slot = FFI::MemoryPointer.new :int
      slot.put_int
      id = FFI::MemoryPointer.new :int
      id.put_int

      C.CXCMD_CheckIfConnected
    end

    def ready?
      check_returncode CXCMD_TestUnitReady(@slot, @id)
    end

    def get_current_card_position
      pos = FFI::MemoryPointer.new :char, 8

      check_returncode C.CXCMD_ReadPosition(@slot, @id, pos)

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
      resp = ps.read_bytes(8)

      card_position = { pu: nil, position: nil, load_mode: nil}
      card_position[:pu] = resp[0].to_s(2)[-3].to_i == 1 ? :no_card_in_printer, :card_in_printer

      card_position[:position] = case resp[7]
        when 0 then :retransfer
        when 1 then :contact
        when 2 then :contactless
        when 3 then :magnetstripe
        else raise "Invalid card_position: #{resp[7].inspect}!"
      end

      card_position[:load_mode] = resp[1].to_s(2)[-1].to_i == 1 ? :right_side : :card_tray

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
    def set_image_layer(layer, data, buffer=0)
      buffer = Buffer2Code[buffer] ? Buffer2Code[buffer] : buffer
      layer = Layer2Code[layer] ? Layer2Code[layer] : layer

      check_returncode C.CXCMD_ImageOut(@slot, @id, data, data.size, layer, buffer)
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
      backside: 0
    }

    PrintColor2Code {
      YMC: 0b1,
      K: 0b10,
      UV: 0b100,
      PeelOff: 0b1000
    }
    def print(color: [:YMC, :K], buffer=0, async=false)
      buffer = Buffer2Code[buffer] ? Buffer2Code[buffer] : buffer
      color = color.map{|c| PrintColor2Code[c] }.inject(&:&) if color.kind_of?(Array)
      async = async ? 1 : 0

      check_returncode C.CXCMD_Print(@slot, @id, color, buffer, async)
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

      check_returncode C.CXCMD_LoadCard(@slot, @id, pos, flip, adjusted, async)
    end

    def move_card(pos=:retransfer, flip=false, adjusted=false, async=false)
      pos = Position2Code[pos] ? Position2Code[pos] : pos
      flip = flip ? 1 : 0
      adjusted = adjusted ? 1 : 0 # This setting is effective only when Destination is NG Card outlet
      async = async ? 1 : 0

      check_returncode C.CXCMD_MoveCard(@slot, @id, pos, flip, adjusted, async)
    end

    def retransfer_and_eject(async=false)
      async = async ? 1 : 0
      check_returncode C.CXCMD_RetransferAndEject(@slot, @id, async)
    end

    def retransfer_and_eject(async=false)
      async = async ? 1 : 0
      check_returncode C.CXCMD_RetransferAndTurn(@slot, @id, async)
    end

    # MS Encoding
    attach_function :CXCMD_WriteMagData, [:int, :int, :pointer, :int, :int], :int
    attach_function :CXCMD_ReadMagData, [:int, :int, :pointer, :pointer, :int], :int

    # Reset
    attach_function :CXCMD_RezeroUnit, [:int, :int], :int

    # Infos & Settings
    attach_function :CXCMD_ModeSense, [:int, :int, :pointer], :int
    attach_function :CXCMD_ModeSelect, [:int, :int, :int, :pointer], :int
    attach_function :CXCMD_LogSense, [:int, :int, :int, :pointer], :int
    attach_function :CXCMD_LogSelect, [:int, :int], :int
    attach_function :CXCMD_RezeroUnit, [:int, :int], :int
    attach_function :CXCMD_RezeroUnit, [:int, :int], :int
    attach_function :CXCMD_RezeroUnit, [:int, :int], :int
    attach_function :CXCMD_RezeroUnit, [:int, :int], :int



    private
    def check_returncode(code)
      code
    end
  end
end
