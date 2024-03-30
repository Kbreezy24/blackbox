; probeTools.G
; Original author: Haytham Bennani (H2B on Jubilee Discord - https://discord.gg/jubilee)
; This Macro is further tuned for use with Blackbox CE
; Firmware: RRF3.4.x and above
; This macro file utilizes the sexbolt Z switch by L.E.O.P.A.R.D and HartK to automatically set Z offsets on the Blackbox CE Toolchanger
; USAGE NOTES: 
;       - update the variables plateX and plateY as needed to reflect the actual position of your probe in your machine coordinates.
;       - ensure all your tools are at printing temperatures for best results
;       - ensure all your tool nozzles are clean from material and/or debris before probing, and its recommended to unload filaments from your tools before probing to ensure nothing flows out of the nozzle during the probing cycle
;       - this file is designed to probe 3 tools; if you have less, comment out the relevant lines in the code as needed. If you have more tools, add the necessary calculation variables and probing sequence and results as needed.
;       !! - ensure your definition for your doorknob probe (M558 line below) is correct for your setup !!
;
; DISCLAIMER: You bear full responsibility and accountability for using this script, and the author is not liable, nor responsible, nor accountable for any damage or misuse of this script.
;4.3mm above bed = Trigger point for sexbolt
; ----------------------------------------------- machine setup
; probe X and Y coordinates
var plateX = 267.6
var plateY = 267.7
var staticOffset = 0.4 ;Static modifier based on unique trigger height
; set acceleration values for P&T for smoother movement
M204 T4000 P4000
; instantaneous velocity change limits for smoother movement
M566 X400 Y400 P1
; re-define doorknob probe in case it is missing
M558 K1 P8 C"^io5.in" F200 H50
; disable any mesh compensation applied to the machine
M561

; ----------------------------------------------- calculation variables
; endstop trigger machine position
var endstopPoint = 0
; endstop doorknob trigger machine position
var probePoint = 0
; final tool offset variables
var t0_offset = 0
var t1_offset = 0

; ----------------------------------------------- probing sequence
echo "***** Probing endstop to doorknob trigger height difference.."
; unload tools (in case we've left anything on the carriage
T-1
; drop bed slightly and move to probe point
G91 G1 Z5 G90
G90 G1 X{var.plateX} F6000
G90 G1 Y{var.plateY} F6000
;probe with doorknob probe (K1)
G30 S-1 K1
; save trigger position
set var.probePoint = move.axes[2].machinePosition
; drop bed slightly, and re-probe with default Z endstop (K0)
G91 G1 Z3 G90
G30 S-1 K0
; save trigger position
set var.endstopPoint = move.axes[2].machinePosition
; calculate trigger height difference between doorknob and endstop
var offsetProbe =  var.endstopPoint - var.probePoint
; drop bed before next operation for clearance
G91 G1 Z5 G90

; ----------------------------------------------- Tool 0
echo "***** Measuring T0 offset.."
T0
; drop bed slightly and move to probe point
G91 G1 Z5 G90
G90 G1 X{var.plateX} Y{var.plateY} F6000
; probe tool with doorknob probe (K1)
G30 S-1 K1
; capture trigger height and calulate initial offset (without endstop trigger height adjustment)
set var.t0_offset = move.axes[2].machinePosition - var.probePoint 
; apply endstop trigger height adjustment for final offset value
set var.t0_offset = var.offsetProbe - var.t0_offset + var.staticOffset ; final value compensates for switch overtravel
; drop bed before next operation for clearance
G91 G1 Z5 G90

; ----------------------------------------------- Tool 1
echo "***** Measuring T1 offset.."
T1
; drop bed slightly and move to probe point
G91 G1 Z5 G90
G90 G1 X{var.plateX} Y{var.plateY} F6000
; probe tool with doorknob probe (K1)
G30 S-1 K1
; capture trigger height and calulate initial offset (without endstop trigger height adjustment)
set var.t1_offset = move.axes[2].machinePosition - var.probePoint
; apply endstop trigger height adjustment for final offset value
set var.t1_offset = var.offsetProbe - var.t1_offset + var.staticOffset ; final value compensates for switch overtravel
; drop bed before next operation for clearance
G91 G1 Z5 G90


; ----------------------------------------------- Re-measure endstop trigger height
; unload tools
T-1
; drop bed slightly and move to probe point
G91 G1 Z5 G90
G90 G1 X{var.plateX} Y{var.plateY} F6000
echo "***** Confirming trigger height difference.."
; drop bed slightly, and probe with doorknob probe (K1)
G91 G1 Z5 G90
G30 S-1 K1
; save trigger position
set var.probePoint = move.axes[2].machinePosition
; drop bed slightly, and re-probe with default Z endstop (K0)
G91 G1 Z5 G90
G30 S-1 K0
; save trigger position
set var.endstopPoint = move.axes[2].machinePosition
; calculate trigger height difference between doorknob and endstop
var offsetProbe2 =  var.endstopPoint - var.probePoint
; drop bed before next operation for clearance
G91 G1 Z5 G90
; enable mesh
G29 S1
; send carriage to middle bed
G0 X150 Y150 F6000

; ----------------------------------------------- Probe Report
echo "----------------------------------------------------------------"
echo "                    Calibration setup data"
echo "Initial probe offset: " ^ var.offsetProbe
echo "Final probe offset: " ^ var.offsetProbe2
echo "----------------------------------------------------------------"
echo "                   Calculated tool offsets"
echo "T0 Z offset: " ^ var.t0_offset
echo "T1 Z offset: " ^ var.t1_offset

echo "----------------------------------------------------------------"
echo "                 G10 commands for config file"
echo "G10 P0 Z" ^ var.t0_offset
echo "G10 P1 Z" ^ var.t1_offset

echo "----------------------------------------------------------------"
; ----------------------------------------------- Apply offsets to tools
G10 P0 Z{var.t0_offset}
G10 P1 Z{var.t1_offset}

; ----------------------------------------------- Prompt user to save offsets to config
echo "Probing completed: offsets are applied to current tools."
echo "Please save G10 commands to config.g for persistence if needed."