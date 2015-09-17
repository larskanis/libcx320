require "libcx320/version"
require "libcx320/error_handling"
require "libcx320/cx320"

module LibCX320
  autoload :DeviceDll, "libcx320/device_dll"
  autoload :DeviceUsb, "libcx320/device_usb"
  autoload :DeviceSimu, "libcx320/device_simu"
end
