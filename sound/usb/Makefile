# SPDX-License-Identifier: GPL-2.0
#
# Makefile for ALSA
#

# mixer_s1810c has a large stack frame; suppress the warning per-file
CFLAGS_mixer_s1810c.o		+= -Wno-frame-larger-than

snd-usb-audio-objs := 	card.o \
			clock.o \
			endpoint.o \
			format.o \
			helper.o \
			implicit.o \
			mixer.o \
			mixer_quirks.o \
			mixer_scarlett.o \
			mixer_scarlett_gen2.o \
			mixer_us16x08.o \
			mixer_s1810c.o \
			pcm.o \
			power.o \
			proc.o \
			quirks.o \
			stream.o \
			validate.o

snd-usb-audio-$(CONFIG_SND_USB_AUDIO_USE_MEDIA_CONTROLLER) += media.o
