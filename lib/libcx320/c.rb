require 'ffi'

module LibCX320
  module C
    extend FFI::Library

    ffi_lib 'PCP05CT.DLL'

    # Get Handle
    attach_function :CXCMD_ScanCX320, [:pointer, :pointer], :int
    attach_function :CXCMD_ScanCX320Next, [:pointer, :pointer], :int

    # Checks
    attach_function :CXCMD_CheckIfConnected, [:pointer, :pointer], :bool
    attach_function :CXCMD_TestUnitReady, [:int, :int], :int

    # Print & CardControl
    attach_function :CXCMD_ReadPosition, [:int, :int, :pointer], :int
    attach_function :CXCMD_ImageOut, [:int, :int, :pointer, :int, :int, :int], :int
    attach_function :CXCMD_DefineLUT, [:int, :int, :int, :int, :pointer], :int
    attach_function :CXCMD_Print, [:int, :int, :int, :int, :int], :int
    attach_function :CXCMD_LoadCard, [:int, :int, :int, :int, :int, :int], :int
    attach_function :CXCMD_MoveCard, [:int, :int, :int, :int, :int, :int], :int
    attach_function :CXCMD_RetransferAndEject, [:int, :int, :int], :int
    attach_function :CXCMD_RetransferAndTurn, [:int, :int, :int], :int

    # MS Encoding
    attach_function :CXCMD_WriteMagData, [:int, :int, :pointer, :int, :int], :int
    attach_function :CXCMD_ReadMagData, [:int, :int, :pointer, :pointer, :int], :int
    attach_function :CXCMD_ICControl, [:int, :int, :int, :int], :int

    # Reset
    attach_function :CXCMD_RezeroUnit, [:int, :int], :int

    # Infos & Settings
    attach_function :CXCMD_ModeSense, [:int, :int, :pointer], :int
    attach_function :CXCMD_ModeSelect, [:int, :int, :int, :pointer], :int
    attach_function :CXCMD_LogSense, [:int, :int, :int, :pointer], :int
    attach_function :CXCMD_LogSelect, [:int, :int], :int
  end
end
