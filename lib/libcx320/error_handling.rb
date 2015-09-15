module LibCX320
  module ErrorHandling
    class Error < RuntimeError
    end

    class UnexpectedPacket < Error
    end

    class PrinterError < Error
      attr_reader :code
      def initialize(text, code)
        super(text)
        @code = code
      end
    end

    class UnknownPrinterError < PrinterError
    end

    ErrorById = {
      0x102D000 => ["No card", "There is no card, or the hopper tray is not closed."],
      0x202D100 => ["Door Open", "Printer door is opened."],
      0x302D300 => ["Busy of Transporting", "Busy because of transporting card or retransferring. Note: This error is not returnd from functions. Control Function returns positive value as BUSY."],
      0x402D400 => ["Busy of Printing", "Busy because of printing. Note: This error is not returnd from functions. Control Function returns positive value as BUSY."],
      0x502D500 => ["Busy of Transporting and Printing", "Busy because of both “Busy of Transporting” and “Busy of Transporting and Printing”. Note: This error is not returnd from functions. Control Function returns positive value as BUSY."],
      0x602D600 => ["No Cassette", "Ink ribbon cassette is not attached, or/and Retransfer film cassette is not attached."],
      0x702D700 => ["No Cleaning Ro.", "Cleaning roller is not attached."],
      0x802DA00 => ["Preheating", "Printer is on the way of preheating."],
      0x902DB00 => ["Initializing", "Printer is on the way of initializing."],
      0x1002DC00 => ["Testing or Cleaning", "Printer is on the way of Off-line Test or cleaning."],
      0x1102DD00 => ["On Setting or Transport Mode", "Printer is in the setting mode or transporting mode."],
      0x1202DE00 => ["Not Ready for Download", "Firmware download cannot be done as printer is not in Download mode."],
      0x1302FD00 => ["Sleeping", "Printer is in the power save mode. Note) To exit this, initializing printer, which is pressing ENTER button after RESET button or sending REZERO command, is required."],
      0x1402FE00 => ["Password Error", "Password certification is not done."],


      0x15039000 => ["Jam(Hopper)", "The card does not arrive the card supply sensor within a predefined time."],
      0x16039100 => ["Jam(TurnOver)", "The card does not arrive the sensor inside the turnover unit within a predefined time."],
      0x17039200 => ["Jam(MG)", "The card does not arrive at the card edge sensor within a predefined time after leaving turnover unit. Also in case of magnetic encoding, when detection by the start position sensor of the MG unit is not possible."],
      0x18039300 => ["Jam(Transfer)", "The card does not arrive the card outlet sensor within a predefined time after leaving the card edge sensor."],
      0x19039400 => ["Jam(Discharge)", "The card stops at the card outlet sensor."],
      0x20039500 => ["Load Failure", "The card is not loaded within 10 seconds in Right Side Card Loading mode. Note) Load Card command can be accepted even if this error is activated."],
      0x2103A000 => ["Media Broken", "Retransfer film is broken."],
      0x2203A100 => ["Media Search", "Mark on the retransfer film could not be detected."],
      0x2303AD00 => ["MG Write Error", "Writing error to the magnetic stripe happens."],
      0x2403AE00 => ["MG Read Error", "Reading error from the magnetic stripe happens."],
      0x2503B000 => ["Ink Broken", "Ink ribbon is broken."],
      0x2603B100 => ["Ink Search", "Mark on the ink ribbon could not be detected, or TAG on the ink ribbon is invalid."],
      0x2703BB00 => ["EXT. Jam", "Card jam happens in the external IC unit."],


      0x28044400 => ["Hardware", "Time out was detected by the printer firmware."],
      0x2904A900 => ["MG Unconnected", "MG unit is not attached correctly."],
      0x3004AB00 => ["MG Mechanical", "Mechanical error happens in the MG unit."],
      0x3104AC00 => ["MG Hardware", "Hardware error happens in the MG unit."],
      0x3204AF00 => ["MG Communicate", "Communication error happens between printer and MG unit."],
      0x3304B900 => ["EXT. Unconnected", "External IC unit is not attached correctly."],
      0x3404BA00 => ["EXT. SW Setting", "Dip switch setting in the external IC unit is not correct."],
      0x3504BE00 => ["EXT. Communicate", "Communication error happens between printer and external IC unit."],
      0x3604BF00 => ["EXT2. Communicate", "Communication error happens between printer and laminator."],
      0x3704C000 => ["Turn Over Unit", "Turnover unit is out of order."],
      0x3804C100 => ["Heater Cam", "Heater Cam is out order."],
      0x3904D800 => ["Hardware", "Circuit trouble was detected at the initialization. Ex. Vth power cannot be put out from the power supply unit."],
      0x4004F000 => ["TR Overheat", "The temperature of retransfer roller is too hot."],
      0x4104F100 => ["TR Broken", "Retransfer roller is out of order."],
      0x4204F200 => ["TR Sensor Broken", "Retransfer roller thermister is out of order."],
      0x4304F300 => ["RR Overheat", "The temperature of bend remdil roller is too hot."],
      0x4404F400 => ["RR Broken", "Bend remdil roller is out of order."],
      0x4504F500 => ["RR Sensor Broken", "Bend remdil roller thermister is out of order."],
      0x4604F600 => ["Overcool", "The temperature in the printer is too cool."],
      0x4704F800 => ["Head Overheat", "The temperature of the thermal head is too hot."],
      0x4804FA00 => ["EEPROM Broken", "EEPROM on the CPU circuit board or the head EEPROM is defective."],


      0x49051A00 => ["Parameter List Length Error", "The content of command is invalid. Parameter list length value in CDB or Page Data is invalid."],
      0x50052000 => ["Invalid Command Operation Code", "The content of command is invalid. Operation Code in CDB is invalid."],
      0x51052400 => ["Illegal Field in CDB", "The content of command is invalid. The data in CDB is invalid."],
      0x52052500 => ["Invalid LUN", "The content of command is invalid. LUN value in CDB is invalid."],
      0x53052600 => ["Invalid Field in Parameter List", "The content of command is invalid. The data in Page Data is invalid."],
      0x54052700 => ["Invalid Color Code in CDB", "Invalid ink is specified.."],
      0x55052A00 => ["Command Sequence Error", "The command is issued in bad order. Ex. Load Card is done when the card is in the printer."],
      0x56052B00 => ["MG Data Error", "MG data from the host computer is invalid."],
      0x57052C00 => ["IC Encoder not installed", "There is no specified IC Encoder."],
      0x58052D00 => ["MG Encoder not installed", "There is no specified MG Encoder."],
      0x5905FB00 => ["Invalid Download Data", "Download data from the host computer is invalid."],
      0x60062800 => ["Medium Changed", "Printer was initialized by pressing RESET button."],
      0x61062900 => ["Power On or Bus Device Reset Occurred", "Printer was initialized by turning on the printer power."],
      0x6242A200 => ["Media Run Out", "End of retransfer film is detected."],
      0x6342B200 => ["Ink Run Out", "End of ink ribbon is detected."],
    }

    ErrorById.each do |id, tt|
      name, text = tt
      klname = name.gsub(/[^a-z0-9]*/i, " ")
      klass = Class.new(PrinterError)
      const_set(klname, klass)
      tt << klass
    end

    def check_returncode(code)
      return code if code==0
      mc = -code
      codes = [mc >> 24 & 0xff, mc >> 16 & 0xff, mc >> 8 & 0xff, mc & 0xff]
      klname, text, klass = ErrorById[mc]

      if klname
        raise klass.new("CX320: %s (code %02x %02x %02x %02x)" % [text, *codes], code)
      else
        raise UnknownPrinterError.new("CX320: error %02x %02x %02x %02x" % codes, code)
      end
    end
  end
end
