# SPDX-License-Identifier: GPL-2.0
#
# Makefile for io_uring

obj-$(CONFIG_IO_URING)		+= io_uring.o
obj-$(CONFIG_IO_WQ)		+= io-wq.o

# io_uring has large stack frames that exceed the default 2048-byte limit
CFLAGS_io_uring.o		+= -Wno-frame-larger-than
