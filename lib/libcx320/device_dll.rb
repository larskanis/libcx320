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
      rescue NoPrinter, NoMorePrinter
      else
        devs << new(slot.read_int, id.read_int)
      end

      loop do
        slot.write_int slot.read_int
        id.write_int id.read_int

        begin
          check_returncode C.CXCMD_ScanCX320Next(slot, id)
        rescue NoPrinter, NoMorePrinter
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

    def close
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


    def write_mag(format, _len, data)
      cdata = FFI::MemoryPointer.from_string(data)
      check_returncode C.CXCMD_WriteMagData(@slot, @id, cdata, data.bytesize, format)
    end

    def read_mag(format, _len)
      cdata = FFI::MemoryPointer.new(:char, 105)
      clen = FFI::MemoryPointer.new(:int)
      clen.write_int cdata.size
      check_returncode C.CXCMD_ReadMagData(@slot, @id, cdata, clen, format)
      cdata.get_bytes(0, clen.read_int)
    end

    def ic_control(type, action)
      check_returncode C.CXCMD_ICControl(@slot, @id, type, action)
    end

    def mode_sense(page, len)
      cdata = FFI::MemoryPointer.new(:char, len)
      check_returncode C.CXCMD_ModeSense(@slot, @id, page, cdata)
      cdata.get_bytes(0, cdata.size)
    end

    def mode_select(page, data)
      cdata = FFI::MemoryPointer.from_string(@slot, @id, data)
      check_returncode C.CXCMD_ModeSelect(@slot, @id, page, cdata)
    end

    def log_sense(page, len)
      cdata = FFI::MemoryPointer.new(:char, len)
      check_returncode C.CXCMD_LogSense(@slot, @id, page, cdata)
      cdata.get_bytes(0, cdata.size)
    end

    def log_select
      check_returncode C.CXCMD_LogSelect(@slot, @id)
    end
  end
end
