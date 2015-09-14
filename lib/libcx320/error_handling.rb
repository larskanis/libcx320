module LibCX320
  module ErrorHandling
    class Error < RuntimeError
    end
  
    class UnexpectedPacket < Error
    end

    class DeviceError < Error
      attr_reader :code
      def initialize(text, code)
        super(text)
        @code = code
      end
    end
    
    def check_returncode(code)
      return code if code==0
      mc = -code
      raise DeviceError.new("CX320: error %02x %02x %02x %02x" % [mc >> 24 & 0xff, mc >> 16 & 0xff, mc >> 8 & 0xff, mc & 0xff], code)
    end
  end
end
