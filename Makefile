libusb_CFLAGS = $(shell pkg-config --cflags libusb-1.0)
libusb_LIBS = $(shell pkg-config --libs libusb-1.0)

override CFLAGS += $(libusb_CFLAGS)
override LDFLAGS += $(libusb_LIBS)

all: ak78tool

clean:
	rm -f ak78tool
