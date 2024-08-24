#!/opt/intelFPGA_lite/18.1/quartus/bin/quartus_stp -t

#   jtagbridge.tcl - Virtual JTAG proxy for Altera devices

package require Tk
init_tk

source [file dirname [info script]]/../../EightThirtyTwo/tcl/vjtagutil.tcl

set CMD_STATUS 0x00
set CMD_READ 0x01
set CMD_WRITE 0x02
set CMD_SETBAUD 0x03
set CMD_RESET 0xff


####################### Main code ###################################


proc send_cmd {cmd data} {
	global connected
	set contmp $connected;
	set connected 0
	if {$contmp} {
		if [ vjtag::usbblaster_open ] {
			vjtag::send [expr (($cmd << 24) | $data) ]
		}
		vjtag::usbblaster_close
	}
	set connected $contmp
}


proc recv {} {
	global connected
	set contmp $connected;
	set connected 0
	set result 0
	if {$contmp} {
		if [ vjtag::usbblaster_open ] {
			set result [vjtag::recv]
		}
		vjtag::usbblaster_close
	}
	set connected $contmp
	return $result
}


proc send_string {cmd data} {
	global connected
	set contmp $connected;
	set connected 0
	if {$contmp} {
		if [ vjtag::usbblaster_open ] {
			foreach char [split $data ""] {
				set c [scan $char "%c"]
				vjtag::send [expr (($cmd << 24) | $c) ]
			}
		}
		vjtag::usbblaster_close
	}
	set connected $contmp
}


proc send_list {cmd args} {
	global connected
	set contmp $connected;
	set connected 0
	if {$contmp} {
		if [ vjtag::usbblaster_open ] {
			foreach val $args {
#				puts $val
				vjtag::send [expr (($cmd << 24) | $val) ]
			}
		}
		vjtag::usbblaster_close
	}
	set connected $contmp
}



proc drain {} {
	global connected
	set contmp $connected;
	set connected 0
	set result 0
	if {$contmp} {
		if [ vjtag::usbblaster_open ] {
			while {$result>=0} {
				set result [vjtag::recv]
				if {$result>0} {						
					puts -nonewline [format "%c" $result]
					if {$result == 13} { puts "" }
				}
			}
		}
		vjtag::usbblaster_close
	}
	set connected $contmp
	return $result
}

proc connect {} {
	global displayConnect
	global connected
	set connected 0

	if { [vjtag::select_instance 0x0232] < 0} {
		set displayConnect "Connection failed\n"
		set connected 0
	} else {
		set displayConnect "Connected to:\n$::vjtag::usbblaster_name\n$::vjtag::usbblaster_device"
		set connected 1
	}
}

proc sleep {delay} {
	after $delay set stop_wait &
	vwait stop_wait
}

proc set_baud {{baud 115200}} {
	global CMD_SETBAUD
	set div [expr 28360000 / $baud]
	send_cmd $CMD_SETBAUD $div 
}

global connected

set message1 [list 0x90 0x70 0x32 ]
set message2 [list 0x80 0x70 0x00 ]

if {[connect]} {

	send_cmd $CMD_RESET 0

	set_baud 31250

	send_cmd $CMD_READ 0
	drain

	set i 0
	while {$i < 40} {
		send_list $CMD_WRITE {*}$message1
		after 20
		send_list $CMD_WRITE {*}$message2
		after 20
		incr i
    }

} else {
	puts "Can't connect"
}

##################### End Code ########################################

