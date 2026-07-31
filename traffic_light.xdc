## ============================================================
## Traffic Light Controller - XDC Constraints
## Board: Real Digital Boolean Board
## Pins confirmed from official board interface pinout table
## ============================================================

## Clock
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports {clk}]
create_clock -period 10.000 [get_ports clk]
## Reset -- btn[0], normally low, drives high when pressed
set_property -dict {PACKAGE_PIN V2 IOSTANDARD LVCMOS33} [get_ports {rst}]

## Priority inputs -- btn[1] and btn[2], normally low, drive high when pressed
set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports {priority_ns}]
set_property -dict {PACKAGE_PIN U1 IOSTANDARD LVCMOS33} [get_ports {priority_ew}]

## btn[3] (J1) is spare -- not used in this design

## ------------------------------------------------------------
## Traffic light outputs -- dedicated onboard LEDs (active-high:
## drive logic '1' to turn on, per board reference table)
## ------------------------------------------------------------
set_property -dict {PACKAGE_PIN G1 IOSTANDARD LVCMOS33} [get_ports {ns_red}]
set_property -dict {PACKAGE_PIN G2 IOSTANDARD LVCMOS33} [get_ports {ns_yellow}]
set_property -dict {PACKAGE_PIN F1 IOSTANDARD LVCMOS33} [get_ports {ns_green}]
set_property -dict {PACKAGE_PIN F2 IOSTANDARD LVCMOS33} [get_ports {ew_red}]
set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS33} [get_ports {ew_yellow}]
set_property -dict {PACKAGE_PIN E2 IOSTANDARD LVCMOS33} [get_ports {ew_green}]