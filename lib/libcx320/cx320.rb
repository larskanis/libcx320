
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
      @dev.close if @dev
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
      color = color.map{|c| PrintColor2Code[c] }.inject(0, &:|) if color.kind_of?(Array)
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

    class AttrDescription < Struct.new(:name, :offs_read, :offs_write, :typ, :params)
      def to_attribute
        ext_type, ext_params = case typ
        when :byte
          [ :int, params || (0..0xff) ]
        when :word
          [ :int, params || (0..0xffff) ]
        when :dword
          [ :int, params || (0..0xffffffff) ]
        when :set, :ascii
          [ typ, params ]
        else
          raise "invalid attr type #{typ}"
        end
        Attribute.new(name, !!offs_write, ext_type, ext_params)
      end
    end

    Attribute = Struct.new(:name, :writeable, :typ, :params, :value)

    def self.to_attr_desc(hash)
      hash.map do |key, args|
        AttrDescription.new(key, *args).freeze
      end.freeze
    end

    def self.merge_with_range(range, hash)
      range.to_a.inject({}){|h,v| h[v] = v.to_s; h }.merge(hash).sort_by{|k,v| k }.inject({}){|h,(k,v)| h[k]=v; h }
    end

    ModeSenseInkAttrs = to_attr_desc({
      ink_code: [2, nil, :set, {0x00 => 'YMCK', 0x02 => 'YMCK-PO', 0x03 => 'K', 0x04 => 'YMCKK', 0x05 => 'YMCK-UV'}],
      ink_number_printed: [4, nil, :word],
      ink_lot_number: [8, nil, :ascii, 6],
    })

    ModeSensePrintAttrs = to_attr_desc({
      print_resolution_x: [4, nil, :word],
      print_resolution_y: [6, nil, :word],
      print_card_size_x: [12, nil, :word],
      print_card_size_y: [14, nil, :word],
      print_mg_mode: [17, nil, :set, {0 => 'None', 1 => 'MAG Encoder', 2 => 'JIS MAG Encoder'}],
      print_ic_mode_contact: [18, nil, :set, {0 => 'None', 1 => 'Embedded IC Encoder', 2 => 'External IC Encoder'}],
      print_ic_mode_contactless: [19, nil, :set, {0 => 'None', 2 => 'External small IC Encoder', 3 => 'External large IC Encoder'}],
      print_film_code: [20, 17, :set, {0 => 'Standard (1000 panels)', 2 => 'Standard (750panels)'}],
      print_ink_code: [21, nil, :set, {0 => 'YMCK', 2 => 'YMCK-PO', 3 => 'K', 4 => 'YMCKK', 5 => 'YMCK-UV'}],
      print_card_code: [22, 19, :set, {0 => 'Standard', 2 => 'Thin card(Card thickness is 0.25mm)'}],
      print_position_x: [24, nil, :word],
      print_position_y: [26, nil, :word],
      print_size_x: [28, nil, :word],
      print_size_y: [30, nil, :word],
      print_roller_temp_retransfer: [33, 4, :byte, 0..5],
      print_velocity_front: [34, 5, :set, merge_with_range(1..11, 0 => "0 (Fast)", 12 => "12 (Slow)")],
      print_velocity_back: [35, 6, :set, merge_with_range(1..11, 0 => "0 (Fast)", 12 => "12 (Slow)")],
      print_roller_temp_card_fix: [36, 7, :byte, 0..5],
      print_velocity_card_fix: [37, 8, :set, {0 => "0 (Slow)", 1 => "1", 2 => "2", 3 => "3", 4 => "4 (Fast)"}],
      print_peel_off_wait_seconds: [39, 10, :byte, 0..15],
      print_revision_number: [40, nil, :byte],
      print_resin_black_energy: [41, 13, :byte, 0..8],
      print_resin_black_mode: [42, 14, :set, {0 => 'Standard', 1 => 'Fine'}],
      print_a0_energy: [43, 15, :byte, 0..8],
      print_a1_energy: [44, 16, :byte, 0..8],
      print_buzzer_mode: [45, 21, :set, {0 => 'Buzzer is enabled', 1 => 'Buzzer is disabled'}],
      print_power_save_minutes: [46, 22, :set, {0 =>'5', 1 =>'10', 2 =>'15', 3 =>'20', 4 =>'25', 5 =>'30', 6 =>'45', 7 =>'60', 8 =>'Off'}],
      print_film_quantity: [47, nil, :byte, 0..10],
      print_ink_quantity: [48, nil, :byte, 0..50],
      print_card_quantity: [49, nil, :set, {0 => 'Greater than 25 cards', 1 => 'From 1 to 24 cards', 2 => 'No cards', 3 => 'Right Side Card loading mode'}],
    })

    ModeSenseEncodeAttrs = to_attr_desc({
      mag_iso_mode: [2, 2, :set, {0 => 'No ISO MAG encoder', 1 => '300 Oe (Lo-Co)', 2 => '2750 Oe (Hi-Co)'}],
      mag_read_write_retry: [7, 7, :byte, 0..3],
    })

    ModeSensePages = {
      ink: [0x23, 4+40, [[ModeSenseInkAttrs, 0]]],
      print: [0x28, 4+50, [[ModeSensePrintAttrs, 0]]],
      mag: [0x2a, 4+10, [[ModeSenseEncodeAttrs, 0]]],
      all: [0x3f, 4+100, [[ModeSenseInkAttrs, 0], [ModeSensePrintAttrs, 40], [ModeSenseEncodeAttrs, 40+50]]],
    }

    LogSenseAttrs = to_attr_desc({
      log_total_count: [8, nil, :dword],
      log_free_count: [16, nil, :dword],
      log_head_count: [24, nil, :dword],
      log_cleaning_count: [32, nil, :dword],
    })

    LogSensePages = {
      log: [0x38, 36, [[LogSenseAttrs, 0]]],
    }

    def mode_sense(page_sym)
      page, len, attr_lists = ModeSensePages[page_sym] || raise("invalid page: #{page_sym.inspect} not in #{ModeSensePages.keys.inspect}")
      data = @dev.mode_sense(page, len)[4..-1]
      lists = attr_lists.map do |attr_list, offset|
        data_to_attrs(data[offset..-1], attr_list)
      end
      lists.inject([], &:+)
    end

    ModeSelectPages = {
      print: [0x28, 23, [[ModeSensePrintAttrs, 0]]],
      mag: [0x2a, 10, [[ModeSenseEncodeAttrs, 0]]],
    }

    def mode_select(page_sym, attrs={})
      page, len, attr_lists = ModeSelectPages[page_sym] || raise("invalid page: #{page_sym.inspect} not in #{ModeSelectPages.keys.inspect}")

      data = [0].pack("C") * len
      data[0, 2] = [0x28, 0x15].pack("CC") if page == 0x28
      data[0, 2] = [0x2a, 0x08].pack("CC") if page == 0x2a
      lists = attr_lists.map do |attr_list, offset|
        data[offset..-1] = attrs_to_data(attr_list, data[offset..-1], attrs)
      end
      raise "invalid data length #{data.bytesize}" if data.bytesize != len
      @dev.mode_select(page, data)
    end

    def log_sense(page_sym)
      page, len, attr_lists = LogSensePages[page_sym] || raise("invalid page: #{page_sym.inspect} not in #{LogSensePages.keys.inspect}")
      data = @dev.log_sense(page, len)
      lists = attr_lists.map do |attr_list, offset|
        data_to_attrs(data[offset..-1], attr_list)
      end
      lists.inject([], &:+)
    end

    def log_select
      @dev.log_select
    end

    def self.mode_sense_attrs(page_sym)
      _page, _len, attr_lists = ModeSensePages[page_sym] || raise("invalid page: #{page_sym.inspect} not in #{ModeSensePages.keys.inspect}")
      attr_lists.map(&:first).inject([], &:+).map{|a| a.to_attribute }
    end

    def self.log_sense_attrs(page_sym)
      _page, _len, attr_lists = LogSensePages[page_sym] || raise("invalid page: #{page_sym.inspect} not in #{LogSensePages.keys.inspect}")
      attr_lists.map(&:first).inject([], &:+).map{|a| a.to_attribute }
    end

    private

    def data_to_attrs(data, attr_list)
      attr_list.map do |attr|
        val = case attr.typ
        when :byte
          data[attr.offs_read, 1].getbyte(0)
        when :word
          data[attr.offs_read, 2].unpack("n")[0]
        when :dword
          data[attr.offs_read, 4].unpack("N")[0]
        when :set
          data[attr.offs_read, 1].getbyte(0)
        when :ascii
          data[attr.offs_read, attr.params]
        else
          raise "invalid attr type #{attr.typ}"
        end

        nattr = attr.to_attribute
        nattr.value = val
        nattr
      end
    end

    def attrs_to_data(attr_list, data, attrs)
      data = data.dup
      attrs.each do |name, value|
        attr = attr_list.find{|a| a.name.to_s == name.to_s }
        raise("invalid attr name #{name.inspect}") unless attr

        case attr.typ
        when :byte
          if attr.params
            raise("value out of range #{attr.params.inspect}: #{value.inspect}") unless attr.params === value
          end
          data[attr.offs_write, 1] = [value].pack("C")
        when :word
          if attr.params
            raise("value out of range #{attr.params.inspect}: #{value.inspect}") unless attr.params === value
          end
          data[attr.offs_write, 2] = [value].pack("n")
        when :dword
          if attr.params
            raise("value out of range #{attr.params.inspect}: #{value.inspect}") unless attr.params === value
          end
          data[attr.offs_write, 4] = [value].pack("N")
        when :set
          val = case value
          when Integer then value
          when String
            attr.params[value] || raise("invalid set value #{value.inspect}")
          else
            raise("invalid set value #{value.inspect}")
          end
          data[attr.offs_write, 1] = [value].pack("C")
        when :ascii
          data[attr.offs_write, attr.params] = value
        else
          raise "invalid attr type #{attr.typ}"
        end
      end
      data
    end
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
