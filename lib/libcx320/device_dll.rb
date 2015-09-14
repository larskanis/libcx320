require 'libcx320/c'

module LibCX320
  class DeviceDll
    extend ErrorHandling
    include ErrorHandling
    
    def self.devices
      slot = FFI::MemoryPointer.new :int
      id = FFI::MemoryPointer.new :int

      devs = [];
      begin
        check_returncode C.CXCMD_ScanCX320(slot, id)
      rescue DeviceError
      else
        devs << new(slot.read_int, id.read_int)
      end
      
      loop do
        slot.write_int slot.read_int
        id.write_int id.read_int

        begin
          check_returncode C.CXCMD_ScanCX320Next(slot, id)
        rescue DeviceError
          # Suche beim ersten Fehler beenden
          break
        else
          devs << new(slot.read_int, id.read_int)
        end
      end
      devs
    end
    
    def initialize(slot, id)
      @slot = slot
      @id = id
    end
    
    def connected?
      slot = FFI::MemoryPointer.new :int
      slot.write_int @slot
      id = FFI::MemoryPointer.new :int
      id.write_int @id

      C.CXCMD_CheckIfConnected(slot, id)
    end

    def ready?
      check_returncode C.CXCMD_TestUnitReady(@slot, @id)
    end

    def rezero_unit
      check_returncode C.CXCMD_RezeroUnit(@slot, @id)
    end

    def get_current_card_position
      pos = FFI::MemoryPointer.new :char, 8
      check_returncode C.CXCMD_ReadPosition(@slot, @id, pos)
      pos.read_bytes(8)
    end

    def image_out(layer, data, buffer)
      check_returncode C.CXCMD_ImageOut(@slot, @id, data, data.size, layer, buffer)
    end
    
    def print(color, buffer, async)
      check_returncode C.CXCMD_Print(@slot, @id, color, buffer, async)
    end
    
    def load_card(pos, flip, adjusted, async)
      check_returncode C.CXCMD_LoadCard(@slot, @id, pos, flip, adjusted, async)
    end

    def move_card(pos, flip, adjusted, async)
      check_returncode C.CXCMD_MoveCard(@slot, @id, pos, flip, adjusted, async)
    end
    
    def retransfer_and_eject(async)
      check_returncode C.CXCMD_RetransferAndEject(@slot, @id, async)
    end

    def retransfer_and_turn(async)
      check_returncode C.CXCMD_RetransferAndTurn(@slot, @id, async)
    end
    
  end
end
