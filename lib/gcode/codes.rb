module Gcode
  # Contains GCodes.
  module Codes
    # Do a rapid move.
    RAPID_MOVE      = 'G0'
    # Do a move at the given or previously given acceleration (F).
    CONTROLLED_MOVE = 'G1'
    # Pause for (P) a given number of milliseconds.
    DWELL           = 'G4'
    # Set head offset (for multiple extruders).
    HEAD_OFFSET     = 'G10'
    # Set units in following commands to be imperial.
    USE_INCHES      = 'G20'
    # Set units in following commands to be metric (default).
    USE_MILLIMETRES  = 'G21'
    # Home axes.
    HOME            = 'G28'
    # Set following commands to use absolute coordinates.
    ABS_POSITIONING = 'G90'
    # Set following commands to use relative coordinates.
    REL_POSITIONING = 'G91'
    # Set current position.
    SET_POSITION    = 'G92'
    # Finish moves, then shutdown (reset required to wake machine).
    STOP            = 'M0'
    # Finish moves the shutdown (sending commands will wake machine).
    SLEEP           = 'M1'
    # Enable motors.
    ENABLE_MOTORS   = 'M17'
    # Disable motors.
    DISABLE_MOTORS  = 'M18'
    # List contents of SD card.
    LIST_SD         = 'M20'
    # Initialize SD card (needed if card wasn't present at bootup).
    INIT_SD         = 'M21'
    # Release SD (safe removal of SD).
    RELEASE_SD      = 'M22'
    # Select SD file (require to print from SD).
    SELECT_SD_FILE  = 'M23'
    # Print selected file from SD (requires file to be selected).
    START_SD_PRINT  = 'M24'
    # Pause printing from SD card.
    PAUSE_SD_PRINT  = 'M25'
    # Set SD position in bytes.
    SET_SD_POSITION = 'M26'
    # Report SD printing status.
    SD_PRINT_STATUS = 'M27'
    # Write following GCodes to given file (requires 8.3 file name).
    START_SD_WRITE  = 'M28'
    # Signal end of SD write, following commands will be executed as normal.
    STOP_SD_WRITE   = 'M29'
    # Power on.
    POWER_ON        = 'M80'
    # Power off.
    POWER_OFF       = 'M81'
    # Set extrusion units in following commands to absolute coordinates.
    ABS_EXT_MODE    = 'M82'
    # Set extrusion units in following commands to relative coordinates.
    REL_EXT_MODE    = 'M83'
    # Trun off powered holding of motors when idle.
    IDLE_HOLD_OFF   = 'M84'
    # Set Extruder tmeperature and return control to host.
    SET_EXT_TEMP_NW = 'M104'
    # Report temperatures
    GET_EXT_TEMP    = 'M105'
    # Trun fans on to given value (S, 0-255).
    FAN_ON          = 'M106'
    # Turn off fans
    FAN_OFF         = 'M107'
    # Set extruder temperature and wait for it to reach temperature.
    SET_EXT_TEMP_W  = 'M109'
    # Reset the line number for the following commands.
    SET_LINE_NUM    = 'M110'
    # Emergency stop.
    EMRG_STOP       = 'M112'
    # Report position.
    GET_POSITION    = 'M114'
    # Report firmware details.
    GET_FW_DETAILS  = 'M115'
    # Wait for temperature (all extruders and bed) to reach the temerature they were set to.
    WIAT_FOR_TEMP   = 'M116'
    # Set bed temperature and return control to host.
    SET_BED_TEMP_NW = 'M140'
    # Set bed temperature and wait for it to reach temperature.
    SET_BED_TEMP_W  = 'M190'
    # Comment symbol
    # @todo Move this to a configurable option.
    COMMENT_SYMBOL  = ';'
  end
end