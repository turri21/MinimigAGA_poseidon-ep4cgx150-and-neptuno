/* minimig_defines.v */
/* 2012, rok.krajnc@gmail.com */

// virtual
`ifdef MINIMIG_VIRTUAL
`define MINIMIG_TOPLEVELDITHER  // Use our own dithering since target boards have 4 or 5 bits per gun
`define MINIMIG_ALTERA
`define MINIMIG_CYCLONE3
`define MINIMIG_VIDEO_FILTER
`define MINIMIG_PARALLEL_AUDIO  // Use own sigma-delta for audio
`define MINIMIG_PS2_KEYBOARD
`define MINIMIG_PS2_MOUSE
`define MINIMIG_HOST_DIRECT // The host can access memory directly, so doesn't need to upload over SPI
`endif

// minimig-de0_nano
`ifdef MINIMIG_DE0_NANO
`define MINIMIG_ALTERA
`define MINIMIG_CYCLONE4
`define MINIMIG_MOR1KX
//`define MINIMIG_VIDEO_FILTER
`define MINIMIG_SERIAL_AUDIO
`define MINIMIG_PS2_KEYBOARD
`define MINIMIG_PS2_MOUSE
`endif

// minimig-de1
`ifdef MINIMIG_DE1
`define MINIMIG_ALTERA
`define MINIMIG_CYCLONE2
//`define MINIMIG_VIDEO_FILTER
`define MINIMIG_PARALLEL_AUDIO
`define MINIMIG_PS2_KEYBOARD
`define MINIMIG_PS2_MOUSE
`endif

// minimig-de2
`ifdef MINIMIG_DE2
`define MINIMIG_ALTERA
`define MINIMIG_CYCLONE2
`define MINIMIG_VIDEO_FILTER
`define MINIMIG_PARALLEL_AUDIO
`define MINIMIG_PS2_KEYBOARD
`define MINIMIG_PS2_MOUSE
`endif

// minimig-avnet
`ifdef MINIMIG_AVNET
`define MINIMIG_XILINX
`define MINIMIG_SPARTAN3
`define MINIMIG_VIDEO_FILTER
`define MINIMIG_SERIAL_AUDIO
`define MINIMIG_PS2_KEYBOARD
`define MINIMIG_PS2_MOUSE
`endif

// mist
`ifdef MINIMIG_MIST
`define MINIMIG_ALTERA
`define MINIMIG_CYCLONE3
`define MINIMIG_VIDEO_FILTER
`define MINIMIG_SERIAL_AUDIO
`endif

