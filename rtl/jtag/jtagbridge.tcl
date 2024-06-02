#!/opt/intelFPGA_lite/18.1/quartus/bin/quartus_stp -t

#   jtagbridge.tcl - Virtual JTAG proxy for Altera devices

package require Tk
init_tk

source [file dirname [info script]]/../../EightThirtyTwo/tcl/vjtagutil.tcl

set CMD_STOP 0x00
set CMD_START 0x01
set CMD_FETCH 0x02
set CMD_GETCOUNT 0x03
set CMD_RESET 0xff

set GRAPHHEIGHT 192
set GRAPHWIDTH 320

set chipcount 0
set kickcount 0
set fast24count 0
set fast32count 0
set totalcount 0

####################### Main code ###################################

proc updatedisplay {} {
	global CMD_GETCOUNT
	global connected
	global totalcount
	send_cmd $CMD_GETCOUNT 
	if {$connected} {
		if [ vjtag::usbblaster_open ] {
			set totalcount [vjtag::recv_blocking ]
		}
		vjtag::usbblaster_close
	}
	after 50 updatedisplay
}



proc send_cmd {cmd} {
	global connected
	set contmp $connected;
	set connected 0
	if {$contmp} {
		if [ vjtag::usbblaster_open ] {
			vjtag::send [expr ($cmd << 24) ]
		}
		vjtag::usbblaster_close
	}
	set connected $contmp
}


proc connect {} {
	global displayConnect
	global connected
	set connected 0

	if { [vjtag::select_instance 0x0068] < 0} {
		set displayConnect "Connection failed\n"
		set connected 0
	} else {
		set displayConnect "Connected to:\n$::vjtag::usbblaster_name\n$::vjtag::usbblaster_device"
		set connected 1
	}
}


proc send_stop {} {
	global CMD_STOP
	send_cmd $CMD_STOP
}

proc send_start {} {
	global CMD_START
	send_reset
	send_cmd $CMD_START
}

proc send_reset {} {
	global CMD_RESET
	send_cmd $CMD_RESET
}

proc drain_fifo {} {
	global connected
	if {$connected} {
		if [ vjtag::usbblaster_open ] {
			while {[vjtag::recv] >-1 } {
			}
			vjtag::usbblaster_close
		}
	}
}


proc send_fetch {} {
	global CMD_STOP
	global CMD_FETCH
	global GRAPHWIDTH
	global GRAPHHEIGHT
	global connected
	global chipcount
	global kickcount
	global fast24count
	global fast32count

	drain_fifo
	send_cmd $CMD_FETCH
	send_cmd $CMD_STOP

	set max {1 1 1 1}

	if {$connected} {
		if [ vjtag::usbblaster_open ] {
			for {set region 0 } {$region < 4} { incr region } {
				for {set bucket 0} {$bucket < 16 } { incr bucket } {
					for {set accesstype 0} {$accesstype < 4} {incr accesstype} {
						set v [vjtag::recv_blocking]
						# Skip over accesstype 1
						if {$accesstype != 1} {
							if {$v > [lindex $max $region]} {
								set max [lreplace $max $region $region $v]
							}
						}
					}
				}
			}
		}
		vjtag::usbblaster_close
	}

	set chipcount [lindex $max 0]
	set kickcount [lindex $max 1]
	set fast24count [lindex $max 2]
	set fast32count [lindex $max 3]

	send_cmd $CMD_FETCH
	send_cmd $CMD_STOP

	set wscale [expr $GRAPHWIDTH / 16]

	.canv1 delete graph
#	.canv2 delete graph
	.canv3 delete graph
	.canv4 delete graph
	.canv5 delete graph
#	.canv6 delete graph
	.canv7 delete graph
	.canv8 delete graph
	.canv9 delete graph
#	.canv10 delete graph
	.canv11 delete graph
	.canv12 delete graph
	.canv13 delete graph
#	.canv14 delete graph
	.canv15 delete graph
	.canv16 delete graph

	if {$connected} {
		if [ vjtag::usbblaster_open ] {
			for {set region 0 } {$region < 4} { incr region } {
				for {set bucket 0} {$bucket < 16 } { incr bucket } {
					for {set accesstype 0} {$accesstype < 4} {incr accesstype} {
						set v [expr [vjtag::recv_blocking] * $GRAPHHEIGHT / [lindex $max $region]]
						switch [expr $region*4 + $accesstype] {
							0 { .canv1 create rectangle [expr $bucket *$wscale] $GRAPHHEIGHT [expr $bucket*$wscale+$wscale] [expr $GRAPHHEIGHT - $v] -fill black -tags graph }
							2 { .canv3 create rectangle [expr $bucket *$wscale] $GRAPHHEIGHT [expr $bucket*$wscale+$wscale] [expr $GRAPHHEIGHT - $v] -fill black -tags graph }
							3 { .canv4 create rectangle [expr $bucket *$wscale] $GRAPHHEIGHT [expr $bucket*$wscale+$wscale] [expr $GRAPHHEIGHT - $v] -fill black -tags graph }
							4 { .canv5 create rectangle [expr $bucket *$wscale] $GRAPHHEIGHT [expr $bucket*$wscale+$wscale] [expr $GRAPHHEIGHT - $v] -fill black -tags graph }
							6 { .canv7 create rectangle [expr $bucket *$wscale] $GRAPHHEIGHT [expr $bucket*$wscale+$wscale] [expr $GRAPHHEIGHT - $v] -fill black -tags graph }
							7 { .canv8 create rectangle [expr $bucket *$wscale] $GRAPHHEIGHT [expr $bucket*$wscale+$wscale] [expr $GRAPHHEIGHT - $v] -fill black -tags graph }
							8 { .canv9 create rectangle [expr $bucket *$wscale] $GRAPHHEIGHT [expr $bucket*$wscale+$wscale] [expr $GRAPHHEIGHT - $v] -fill black -tags graph }
							10 { .canv11 create rectangle [expr $bucket *$wscale] $GRAPHHEIGHT [expr $bucket*$wscale+$wscale] [expr $GRAPHHEIGHT - $v] -fill black -tags graph }
							11 { .canv12 create rectangle [expr $bucket *$wscale] $GRAPHHEIGHT [expr $bucket*$wscale+$wscale] [expr $GRAPHHEIGHT - $v] -fill black -tags graph }
							12 { .canv13 create rectangle [expr $bucket *$wscale] $GRAPHHEIGHT [expr $bucket*$wscale+$wscale] [expr $GRAPHHEIGHT - $v] -fill black -tags graph }
							14 { .canv15 create rectangle [expr $bucket *$wscale] $GRAPHHEIGHT [expr $bucket*$wscale+$wscale] [expr $GRAPHHEIGHT - $v] -fill black -tags graph }
							15 { .canv16 create rectangle [expr $bucket *$wscale] $GRAPHHEIGHT [expr $bucket*$wscale+$wscale] [expr $GRAPHHEIGHT - $v] -fill black -tags graph }
						}
					}
				}
			}
		}
		vjtag::usbblaster_close
	}
}



wm state . normal
wm title . "CPU Profiler"

global connected
set connected 0

frame .frmConnection -relief sunken -borderwidth 2 -padx 5 -pady 5
pack .frmConnection -fill both -expand 1

set  displayConnect "Not yet connected\nNo Interface\nNo Device"
label .lblConn -justify left -textvariable displayConnect
button .btnConn -text "Connect..." -command "connect"
button .btnReset -text "Reset" -command "send_reset"

grid .btnConn -in .frmConnection -row 0 -column 0 -padx 5 -sticky ew
grid .btnReset -in .frmConnection -row 1 -column 0 -padx 5 -sticky ew
grid .lblConn -in .frmConnection -row 0 -column 1 -rowspan 2 -padx 5 -pady 5

frame .frame -relief sunken -borderwidth 2 -padx 5 -pady 5
pack .frame -fill both -expand yes

button .btnStart -text "Start" -command send_start
button .btnStop -text "Stop" -command send_stop
button .btnFetch -text "Fetch" -command send_fetch

canvas .canv1 -width $GRAPHWIDTH -height $GRAPHHEIGHT -background white
#canvas .canv2 -width $GRAPHWIDTH -height $GRAPHHEIGHT -background white
canvas .canv3 -width $GRAPHWIDTH -height $GRAPHHEIGHT -background white
canvas .canv4 -width $GRAPHWIDTH -height $GRAPHHEIGHT -background white
canvas .canv5 -width $GRAPHWIDTH -height $GRAPHHEIGHT -background white
#canvas .canv6 -width $GRAPHWIDTH -height $GRAPHHEIGHT -background white
canvas .canv7 -width $GRAPHWIDTH -height $GRAPHHEIGHT -background white
canvas .canv8 -width $GRAPHWIDTH -height $GRAPHHEIGHT -background white
canvas .canv9 -width $GRAPHWIDTH -height $GRAPHHEIGHT -background white
#canvas .canv10 -width $GRAPHWIDTH -height $GRAPHHEIGHT -background white
canvas .canv11 -width $GRAPHWIDTH -height $GRAPHHEIGHT -background white
canvas .canv12 -width $GRAPHWIDTH -height $GRAPHHEIGHT -background white
canvas .canv13 -width $GRAPHWIDTH -height $GRAPHHEIGHT -background white
#canvas .canv14 -width $GRAPHWIDTH -height $GRAPHHEIGHT -background white
canvas .canv15 -width $GRAPHWIDTH -height $GRAPHHEIGHT -background white
canvas .canv16 -width $GRAPHWIDTH -height $GRAPHHEIGHT -background white

label .fetchlabel -text "Fetch"
grid .fetchlabel -in .frame -row 0 -column 0 -padx 5 -pady 5 -sticky ew
label .readlabel -text "Read"
grid .readlabel -in .frame -row 0 -column 1 -padx 5 -pady 5 -sticky ew
label .writelabel -text "Write"
grid .writelabel -in .frame -row 0 -column 2 -padx 5 -pady 5 -sticky ew

grid .canv1 -in .frame -row 1 -column 0 -sticky ew
#grid .canv2 -in .frame -row 1 -column 1 -sticky ew
grid .canv3 -in .frame -row 1 -column 1 -sticky ew
grid .canv4 -in .frame -row 1 -column 2 -sticky ew
label .chiplabel -text "Chip RAM - max:"
grid .chiplabel -in .frame -row 2 -column 0 -columnspan 2 -padx 5 -pady 5 -sticky e
label .chipcount -textvariable chipcount
grid .chipcount -in .frame -row 2 -column 2 -padx 5 -pady 5 -sticky w

grid .canv5 -in .frame -row 3 -column 0 -sticky ew
#grid .canv6 -in .frame -row 3 -column 1 -sticky ew
grid .canv7 -in .frame -row 3 -column 1 -sticky ew
grid .canv8 -in .frame -row 3 -column 2 -sticky ew
label .kicklabel -text "Kickstart ROM - max:"
grid .kicklabel -in .frame -row 4 -column 0 -columnspan 2 -padx 5 -pady 5 -sticky e
label .kickcount -textvariable kickcount
grid .kickcount -in .frame -row 4 -column 2 -padx 5 -pady 5 -sticky w

grid .canv9 -in .frame -row 5 -column 0 -sticky ew
#grid .canv10 -in .frame -row 5 -column 1 -sticky ew
grid .canv11 -in .frame -row 5 -column 1 -sticky ew
grid .canv12 -in .frame -row 5 -column 2 -sticky ew
label .24label -text "24-bit Fast RAM (and RTG) - max:"
grid .24label -in .frame -row 6 -column 0 -columnspan 2 -padx 5 -pady 5 -sticky e
label .24count -textvariable fast24count
grid .24count -in .frame -row 6 -column 2 -padx 5 -pady 5 -sticky w

grid .canv13 -in .frame -row 7 -column 0 -sticky ew
#grid .canv14 -in .frame -row 7 -column 1 -sticky ew
grid .canv15 -in .frame -row 7 -column 1 -sticky ew
grid .canv16 -in .frame -row 7 -column 2 -sticky ew
label .32label -text "32-bit Fast RAM - max:"
grid .32label -in .frame -row 8 -column 1 -columnspan 1 -padx 5 -pady 5 -sticky e
label .32count -textvariable fast32count
grid .32count -in .frame -row 8 -column 2 -padx 5 -pady 5 -sticky w

grid .btnStart -in .frame -row 8 -column 0 -padx 5 -pady 2 -sticky ew
grid .btnStop -in .frame -row 9 -column 0 -padx 5 -pady 2 -sticky ew
grid .btnFetch -in .frame -row 10 -column 0 -padx 5 -pady 2 -sticky ew

set totalcount 0
label .total -text "Total accesses:"
grid .total -in .frame -row 10 -column 1 -padx 5 -pady 2 -sticky e
label .totalcount -textvariable totalcount
grid .totalcount -in .frame -row 10 -column 2 -padx 5 -pady 2 -sticky w

update

connect
updatedisplay
tkwait window .


##################### End Code ########################################

