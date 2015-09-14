require 'libusb'

module LibCX320
  class DeviceUsb
    include ErrorHandling
    
    attr_reader :devh
    
    def self.devices
      @@ctx = LIBUSB::Context.new
      
      @@ctx.devices(idVendor: 0x04f1, idProduct: 0x4033).map.with_index do |dev, devidx|
        new(dev, devidx)
      end
    end
    
    def bulk_transfer(*args)
      p args
      @devh.bulk_transfer(*args)
    end
    
    def send_command(cdb, data_length, direction=LIBUSB::ENDPOINT_IN)
      ensure_open
      @tag += 1
      expected_tag = @tag
      lun = 0
      len = direction==LIBUSB::ENDPOINT_IN ? data_length : data_length.bytesize

      cbw = ['USBC', expected_tag, len || 0, direction, lun, cdb.length, cdb].pack('a*VVCCCa*')
      cbw = cbw.ljust(31, "\0")

      bulk_transfer(endpoint: 0x02, dataOut: cbw)

      if data_length && direction==LIBUSB::ENDPOINT_IN
        recv = bulk_transfer(endpoint: 0x81, dataIn: data_length)
      elsif data_length
        recv = bulk_transfer(endpoint: 0x02, dataOut: data_length)
      end
      get_status(expected_tag)
      
      return recv
    end

    def get_status(expected_tag)
      retries = 5
      buffer = nil
      begin
        buffer = bulk_transfer(endpoint: 0x81, dataIn: 13, timeout: 999999999)
        dCSWSignature, dCSWTag, dCSWDataResidue, bCSWStatus = buffer.unpack('a4VVC')

        raise UnexpectedPacket, "Unexpected USB packet received" if expected_tag != dCSWTag
        if bCSWStatus != 0
          check_returncode(request_sense_error)
        end
      rescue LIBUSB::ERROR_PIPE, UnexpectedPacket
        if (retries-=1)>=0
          @devh.clear_halt(0x81)
          retry
        end
        raise
      end

      buffer
    end

    def initialize(dev, devidx)
      @dev = dev
      @devidx = devidx
      @tag = 0
      @devh = nil
    end
    
    def ensure_open
      return @devh if @devh
      @devh = @dev.open
      @devh.claim_interface(0)

      # loop do
        # begin
          # bulk_transfer(endpoint: 0x02, dataOut: "USBC\x01\x00\x00\x00`\x00\x00\x00\x80\x00\x06\x12\x00\x00\x00`\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00")
          # p ["clear"]
          # bulk_transfer(endpoint: 0x81, dataIn: 1300, timeout: 100)
        # rescue LIBUSB::ERROR_TIMEOUT
          # break
        # end
      # end

      send_inquiry
      
      @devh
    end
    
    def close
      if @devh
        @devh.release_interface(0)
      end
      @dev.close
    end
    
    def send_inquiry
      expected_length = 0x60 # INQUIRY_LENGTH
      cdb = [ 0x12, 0, 0, # Inquiry
              expected_length, 0,
              ].pack('CCCnC')

      send_command( cdb, expected_length )
    end
    
    def request_sense_error
      expected_length = 0x14
      cdb = [ 0x03, 0, 0, expected_length, 0].pack('CCCnC')
      res = send_command( cdb, expected_length )
      
      -( 0x01 << 24 | res.getbyte(0x02) << 16 | res.getbyte(0x0c) << 8 | 0 )
    end
    
    def ready?
      cdb = [ 0, 0].pack('Nn')
      send_command( cdb, nil)
    end
    
    def rezero_unit
      cdb = [ 1, 0, 0].pack('CCN')
      send_command( cdb, nil)
    end

    def get_current_card_position
      start = 0
      cdb = [ 0x34, 0, # Pre-Fetch(10)
              start, 0,
              0, 0,
              ].pack('CCNCnC')
      expected_length = 0x08

      send_command(cdb, expected_length)
    end
    
    def image_out(layer, data, buffer)
      # todo: send!
    end
    
    def load_move_card(scode, pos, flip, adjusted, async)
      start = 0
      cdb = [ 0x31, scode, # load card
              async, 0,
              flip*2 + adjusted*4, 0, pos, 0,
              ].pack('CCCCCnCn')
      send_command(cdb, nil)
    end

    def load_card(pos, flip, adjusted, async)
      load_move_card(0x01, pos, flip, adjusted, async)
    end

    def move_card(pos, flip, adjusted, async)
      load_move_card(0x0b, pos, flip, adjusted, async)
    end
    
    def retransfer_and_eject(async)
      load_move_card(0x09, 0, 0, 0, async)
    end

    def retransfer_and_turn(async)
      load_move_card(0x0a, 0, 0, 0, async)
    end
  end
end
