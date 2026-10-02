<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

The design generates a 640x480 VGA picture from the 25.175 MHz clock. The
`hvsync_generator` module produces horizontal and vertical sync along with the
current pixel coordinates and an active-video signal. Pixels outside the
display area are black.

Inside the active area, the picture contains a gray grid with 32-pixel spacing
and white horizontal and vertical axes through the center. A 32-entry lookup
table draws a five-pixel-wide green sine wave. Its phase advances at each
vertical-sync edge, making the wave move between frames.

The eight dedicated outputs carry two bits per red, green, and blue channel
plus the horizontal and vertical sync signals. The bidirectional pins are
unused.

## How to test

Run the Cocotb simulation from the `test` directory with `make`. The supplied
test functions currently call `cocotb.pass_test()` immediately, as directed by
the VGA Playground workshop, so they exit successfully without checking the
rendered pixels. Remove those calls and provide matching reference frames
before using the image-comparison portion of the test.

For a visual hardware check, connect the RGB and sync outputs to a compatible
VGA adapter and monitor, apply the 25.175 MHz clock, and release reset. The
monitor should show the grid, centered axes, and animated green sine wave.

## External hardware

A VGA adapter (for example, a compatible VGA PMOD with its required resistor
network) and VGA monitor are needed to view the video output.
