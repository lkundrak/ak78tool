/*
 * AK78xx/AK88xx USB flasher tool
 * Copyright (C) 2020  Lubomir Rintel <lkundrak@v3.sk>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <libusb.h>
#include <unistd.h>
#include <sys/stat.h>

int quiet = 0;

/*
 * USB payload data transfer routines, common to boot and producer modes.
 */

static int
read_data (libusb_device_handle *dev, int fd, int len)
{
	unsigned char pkt[4096] = { 0, };
	int xferred = 0;
	int ret;

	while (len) {
		ret = libusb_bulk_transfer (dev, 0x82, pkt, sizeof(pkt), &xferred, 1000);
		if (ret) {
			fprintf (stderr, "Error reading data: %s\n", libusb_strerror (ret));
			return -1;
		}

		if (xferred > len)
			xferred = len;

		len -= xferred;

		while (xferred) {
			ret = write (fd, pkt, xferred);
			if (ret == -1) {
				perror ("Can't save received data");
				return -1;
			}
			xferred -= ret;
			memmove (pkt, pkt + ret, xferred);
		}
	}

	return 0;
}

static int
write_data (libusb_device_handle *dev, int fd, int len, int remaining)
{
	unsigned char pkt[4096] = { 0, };
	int xferred = 0;
	int to_xfer;
	int ret;

	while (len) {
		if (!quiet) {
			ret = fprintf (stderr, " (%d bytes remaining)   \b\b\b", remaining);
			for (ret -= 6; ret > 0; ret--)
				fputc ('\b', stderr);
		}

		to_xfer = read (fd, pkt, sizeof(pkt));
		if (to_xfer == -1) {
			perror ("read");
			return -1;
		}
		if (to_xfer == 0) {
			perror ("short read");
			return -1;
		}

		ret = libusb_bulk_transfer (dev, 0x03, pkt, to_xfer, &xferred, 1000);
		if (ret) {
			fprintf (stderr, "Write error: %s\n", libusb_strerror (ret));
			return -1;
		}

		if (xferred != to_xfer) {
			fprintf (stderr, "Short write: %d/%ld\n", xferred, sizeof(pkt));
			return -1;
		}

		len -= xferred;
		remaining -= xferred;
	}

	if (!quiet && remaining == 0)
		fprintf (stderr, " done.                    \n");

	return 0;
}

/*
 * Boot mode routines.
 */

static const uint32_t BOOT_NO_ARG = 0x60606060;

enum {
	BOOT_SET_REG = 0x1f,
	BOOT_DOWNLOAD = 0x3f,
	BOOT_DOWNLOAD_DONE = 0x3c,
	BOOT_UPLOAD = 0x7f,
	BOOT_UPLOAD_DONE = 0x7c,
	BOOT_GO = 0x9f,
};

static int
boot_op (libusb_device_handle *dev, uint8_t op, uint32_t f1, uint32_t f2, uint32_t f3)
{
	unsigned char pkt[64];
	int xferred = 0;
	int ret;

	ret = libusb_get_max_packet_size (libusb_get_device (dev), 0x81);
	if (ret < 0) {
		fprintf (stderr, "Can not read EP 0x81 IN packet size: %s\n", libusb_strerror (ret));
		return -1;
	}
	if (ret != 64) {
		fprintf (stderr, "Unexpected EP 0x81 IN packet size: %d\n", ret);
		if (ret == 8)
			fprintf (stderr, "Looks like the device is in producer mode.\n");
		else
			fprintf (stderr, "Looks like the device is not in boot mode.\n");
		fprintf (stderr, "Try resetting the board.\n");
		return -1;
	}

	memset (pkt, 0x60, sizeof(pkt));
	pkt[0x1e] = 0x52;
	pkt[0x1f] = 0x00;
	pkt[0x3e] = 0x13;
	pkt[0x3f] = 0x14;

	pkt[0x31] = op;

	pkt[0x35] = (f1 >> 24) & 0xff;
	pkt[0x34] = (f1 >> 16) & 0xff;
	pkt[0x33] = (f1 >> 8) & 0xff;
	pkt[0x32] = (f1 >> 0) & 0xff;

	pkt[0x39] = (f2 >> 24) & 0xff;
	pkt[0x38] = (f2 >> 16) & 0xff;
	pkt[0x37] = (f2 >> 8) & 0xff;
	pkt[0x36] = (f2 >> 0) & 0xff;

	pkt[0x3d] = (f3 >> 24) & 0xff;
	pkt[0x3c] = (f3 >> 16) & 0xff;
	pkt[0x3b] = (f3 >> 8) & 0xff;
	pkt[0x3a] = (f3 >> 0) & 0xff;

	ret = libusb_bulk_transfer (dev, 0x03, pkt, sizeof(pkt), &xferred, 0);
	if (ret) {
		fprintf (stderr, "Error issuing command 0x%02x: %s\n", op, libusb_strerror (ret));
		return -1;
	}

	if (xferred != sizeof(pkt)) {
		fprintf (stderr, "Short write issuing command 0x%02x: %d/%ld\n", op, xferred, sizeof(pkt));
		return -1;
	}

	return 0;
}

/*
 * Producer mode routines.
 */

static const uint32_t PROD_NO_ARG = 0x00000000;
enum {
	PROD_PING = 0x01,
	PROD_CLEAR = 0x02,
	PROD_WRITE = 0x04,
	PROD_READPART = 0x0b,
	PROD_XIP_PREPARE = 0x14,
	PROD_XIP_CHUNK = 0x15,
	PROD_XIP_FINISH = 0x16,
	PROD_SYNC = 0x1c,
};

static int
prod_prepare (libusb_device_handle *dev, uint8_t op, uint32_t f1, uint32_t f2)
{
	unsigned char pkt[64] = { 0, };
	int xferred = 0;
	int ret;

	ret = libusb_get_max_packet_size (libusb_get_device (dev), 0x81);
	if (ret < 0) {
		fprintf (stderr, "libusb_get_max_packet_size(0x81): %s\n", libusb_strerror (ret));
		return -1;
	}
	if (ret != 8) {
		fprintf (stderr, "Unexpected EP 0x81 IN packet size: %d\n", ret);
		if (ret == 64)
			fprintf (stderr, "Looks like the device is in boot mode.\n");
		else
			fprintf (stderr, "Looks like the device is not in PRODUCER mode.\n");
		fprintf (stderr, "Try loading and running PRODUCER.nb0.\n");
		return -1;
	}

	pkt[0x00] = op;

	pkt[0x03] = (f1 >> 0) & 0xff;
	pkt[0x04] = (f1 >> 8) & 0xff;
	pkt[0x05] = (f1 >> 16) & 0xff;
	pkt[0x06] = (f1 >> 24) & 0xff;

	pkt[0x07] = (f2 >> 0) & 0xff;
	pkt[0x08] = (f2 >> 8) & 0xff;
	pkt[0x09] = (f2 >> 16) & 0xff;
	pkt[0x0a] = (f2 >> 24) & 0xff;

	ret = libusb_bulk_transfer (dev, 0x03, pkt, sizeof(pkt), &xferred, 1000);
	if (ret) {
		fprintf (stderr, "Error submitting command 0x%02x: %s\n", op, libusb_strerror (ret));
		return -1;
	}

	if (xferred != sizeof(pkt)) {
		fprintf (stderr, "Short write submitting command 0x%02x: %d/%ld\n", op, xferred, sizeof(pkt));
		return -1;
	}

	return 0;
}

static int
prod_run (libusb_device_handle *dev)
{
	unsigned char pkt[64] = { 0, };
	int xferred = 0;
	int ret;

	memset (pkt, 0x50, sizeof(pkt));
	pkt[0x1f] = 0x52;
	pkt[0x20] = 0x00;
	pkt[0x3e] = 0x13;
	pkt[0x3f] = 0x14;

	ret = libusb_bulk_transfer (dev, 0x03, pkt, sizeof(pkt), &xferred, 0);
	if (ret) {
		fprintf (stderr, "Error starting command: %s\n", libusb_strerror (ret));
		return -1;
	}

	if (xferred != sizeof(pkt)) {
		fprintf (stderr, "Short write starting command: %d/%ld\n", xferred, sizeof(pkt));
		return -1;
	}

	return 0;
}

static int
prod_check (libusb_device_handle *dev)
{
	unsigned char pkt[64];
	int xferred = 0;
	int ret;

	ret = libusb_bulk_transfer (dev, 0x82, pkt, sizeof(pkt), &xferred, 0);
	if (ret) {
		fprintf (stderr, "Error checking command status: %s\n", libusb_strerror (ret));
		return -1;
	}

	if (xferred != sizeof(pkt)) {
		fprintf (stderr, "Short read of command status.\n");
		return -1;
	}

	if (pkt[0x00] != 0x01 || pkt[0x01] != 0x03 || pkt[0x02] != 0x00 || pkt[0x03] != 0x01) {
		fprintf (stderr, "Command returned an error: %02x %02x %02x %02x\n",
				pkt[0x00], pkt[0x01], pkt[0x02], pkt[0x03]);
		return -1;
	}

	return 0;
}

static libusb_device_handle *
open_dev (libusb_context *ctx)
{
	libusb_device_handle *dev;
	int ret;

	dev = libusb_open_device_with_vid_pid (ctx, 0x0471, 0x0666);
	if (dev == NULL)
		return NULL;

	ret = libusb_claim_interface (dev, 0);
	if (ret) {
		fprintf (stderr, "Error claiming interface 0: %s\n", libusb_strerror (ret));
		libusb_close (dev);
		return NULL;
	}

	return dev;
}

int
main (int argc, char *argv[])
{
	int status = EXIT_FAILURE;
	libusb_device_handle *dev;
	libusb_context *ctx;
	struct stat sb;
	int ret;
	int fd;
	int i;

	if (getenv ("QUIET"))
		quiet = 1;

	ret = libusb_init (&ctx);
	if (ret) {
		fprintf (stderr, "Error initializing libusb: %s\n", libusb_strerror (ret));
		return EXIT_FAILURE;
	}

	dev = open_dev (ctx);
	if (dev == NULL) {
		fprintf (stderr, "Device not found.\n");
		goto err_exit;
	}

	for (i = 1; i < argc; i++) {
		uint32_t f1, f2, f3;

		if (strcmp (argv[i], "go") == 0) {
			if (argc - i < 2) {
				fprintf (stderr, "%s: Not enough arguments.\n", argv[i]);
				goto err_close;
			}

			f1 = strtol(argv[++i], NULL, 0);

			ret = boot_op (dev, BOOT_GO, f1, BOOT_NO_ARG, BOOT_NO_ARG);
			if (ret)
				goto err_close;

		} else if (strcmp (argv[i], "set") == 0) {
			if (argc - i < 3) {
				fprintf (stderr, "%s: Not enough arguments.\n", argv[i]);
				goto err_close;
			}

			f1 = strtol(argv[++i], NULL, 0);
			f3 = strtol(argv[++i], NULL, 0);

			ret = boot_op (dev, BOOT_SET_REG, f1, BOOT_NO_ARG, f3);
			if (ret)
				goto err_close;

		} else if (strcmp (argv[i], "upload") == 0) {
			if (argc - i < 3) {
				fprintf (stderr, "%s: Not enough arguments.\n", argv[i]);
				goto err_close;
			}

			f1 = strtol(argv[++i], NULL, 0);
			f2 = strtol(argv[++i], NULL, 0);
			fd = open (argv[++i], O_WRONLY | O_CREAT, 0666);
			if (fd == -1) {
				perror (argv[i]);
				goto err_close;
			}

			ret = boot_op (dev, BOOT_UPLOAD, f1, f2, BOOT_NO_ARG);
			if (ret)
				goto err_fd;

			ret = read_data (dev, fd, f2);
			if (ret)
				goto err_fd;

			ret = boot_op (dev, BOOT_UPLOAD_DONE, f1, f2, BOOT_NO_ARG);
			if (ret)
				goto err_fd;

			close(fd);

		} else if (strcmp (argv[i], "download") == 0) {
			if (argc - i < 2) {
				fprintf (stderr, "%s: Not enough arguments.\n", argv[i]);
				goto err_close;
			}

			f1 = strtol(argv[++i], NULL, 0);
			fd = open (argv[++i], O_RDONLY);
			if (fd == -1) {
				perror (argv[i]);
				goto err_close;
			}
			ret = fstat (fd, &sb);
			if (ret == -1) {
				perror (argv[i]);
				goto err_close;
			}
			f2 = sb.st_size;

			if (!quiet)
				fprintf (stderr, "Writing %s into memory...", argv[i]);

			ret = boot_op (dev, BOOT_DOWNLOAD, f1, f2, BOOT_NO_ARG);
			if (ret)
				goto err_fd;

			ret = write_data (dev, fd, f2, f2);
			if (ret)
				goto err_fd;

			close(fd);

			ret = boot_op (dev, BOOT_DOWNLOAD_DONE, f1, f2, PROD_NO_ARG);
			if (ret)
				goto err_close;

		} else if (strcmp (argv[i], "sleep") == 0) {
			if (argc - i < 1) {
				fprintf (stderr, "%s: Not enough arguments.\n", argv[i]);
				goto err_close;
			}
			sleep (strtol(argv[++i], NULL, 0));

		} else if (strcmp (argv[i], "ping") == 0) {

			ret = prod_prepare (dev, PROD_PING, PROD_NO_ARG, PROD_NO_ARG);
			if (ret)
				goto err_close;

			ret = prod_run(dev);
			if (ret)
				goto err_close;

			ret = prod_check(dev);
			if (ret)
				goto err_close;

		} else if (strcmp (argv[i], "erase") == 0) {
			if (argc - i < 1) {
				fprintf (stderr, "%s: Not enough arguments.\n", argv[i]);
				goto err_close;
			}

			f1 = strtol(argv[++i], NULL, 0);

			if (!quiet)
				fprintf (stderr, "Erasing...");

			ret = prod_prepare (dev, PROD_CLEAR, f1, PROD_NO_ARG);
			if (ret)
				goto err_close;

			ret = prod_run(dev);
			if (ret)
				goto err_close;

			ret = prod_check(dev);
			if (ret)
				goto err_close;

			if (!quiet)
				fprintf (stderr, " done.\n");

		} else if (strcmp (argv[i], "write") == 0) {
			if (argc - i < 2) {
				fprintf (stderr, "%s: Not enough arguments.\n", argv[i]);
				goto err_close;
			}

			f1 = strtol(argv[++i], NULL, 0);
			fd = open (argv[++i], O_RDONLY);
			if (fd == -1) {
				perror (argv[++i]);
				goto err_close;
			}
			ret = fstat (fd, &sb);
			if (ret == -1) {
				perror (argv[++i]);
				goto err_close;
			}
			f2 = sb.st_size;

			if (!quiet)
				fprintf (stderr, "Writing %s partition...", argv[i]);

			ret = prod_prepare (dev, PROD_WRITE, f1, f2);
			if (ret)
				goto err_fd;

			ret = prod_run(dev);
			if (ret)
				goto err_fd;

			ret = prod_check(dev);
			if (ret)
				goto err_fd;

			ret = write_data (dev, fd, f2, f2);
			if (ret)
				goto err_fd;

			close(fd);

			ret = prod_check(dev);
			if (ret)
				goto err_close;

		} else if (strcmp (argv[i], "ptread") == 0) {
			if (argc - i < 2) {
				fprintf (stderr, "%s: Not enough arguments.\n", argv[i]);
				goto err_close;
			}

			f1 = strtol(argv[++i], NULL, 0);
			fd = open (argv[++i], O_WRONLY | O_CREAT, 0666);
			if (fd == -1) {
				perror (argv[i]);
				goto err_close;
			}

			ret = prod_prepare (dev, PROD_READPART, f1, PROD_NO_ARG);
			if (ret)
				goto err_close;

			ret = prod_run(dev);
			if (ret)
				goto err_close;

			ret = read_data (dev, fd, f1);
			if (ret)
				goto err_fd;

			close(fd);

		} else if (strcmp (argv[i], "ce") == 0) {
			uint32_t remaining;

			f1 = strtol(argv[++i], NULL, 0);
			fd = open (argv[++i], O_RDONLY);
			if (fd == -1) {
				perror (argv[++i]);
				goto err_close;
			}
			ret = fstat (fd, &sb);
			if (ret == -1) {
				perror (argv[++i]);
				goto err_close;
			}
			f2 = sb.st_size;

			if (!quiet)
				fprintf (stderr, "Writing %s CE image...", argv[i]);

			ret = prod_prepare (dev, PROD_XIP_PREPARE, f1, PROD_NO_ARG);
			if (ret)
				goto err_fd;

			ret = prod_run(dev);
			if (ret)
				goto err_fd;

			ret = prod_check(dev);
			if (ret)
				goto err_fd;

			remaining = f2;
			while (remaining) {
				int len = remaining;
				if (len > 0xa00000)
					len = 0xa00000;

				ret = prod_prepare (dev, PROD_XIP_CHUNK, f2 - remaining, len);
				if (ret)
					goto err_fd;

				ret = prod_run(dev);
				if (ret)
					goto err_fd;

				ret = prod_check(dev);
				if (ret)
					goto err_fd;

				ret = write_data (dev, fd, len, remaining);
				if (ret)
					goto err_fd;

				ret = prod_check(dev);
				if (ret)
					goto err_fd;

				remaining -= len;
			}

			close (fd);

			ret = prod_prepare (dev, PROD_XIP_FINISH, f1, PROD_NO_ARG);
			if (ret)
				goto err_close;

			ret = prod_run(dev);
			if (ret)
				goto err_close;

			ret = prod_check(dev);
			if (ret)
				goto err_close;

		} else if (strcmp (argv[i], "sync") == 0) {
			if (!quiet)
				fprintf (stderr, "Waiting for writes to finish...");

			ret = prod_prepare (dev, PROD_SYNC, PROD_NO_ARG, PROD_NO_ARG);
			if (ret)
				goto err_close;

			ret = prod_run(dev);
			if (ret)
				goto err_close;

			ret = prod_check(dev);
			if (ret)
				goto err_close;

			if (!quiet)
				fprintf (stderr, " done.\n");

		} else if (strcmp (argv[i], "waitreset") == 0) {
			int addr1 = libusb_get_device_address (libusb_get_device (dev));
			int addr2 = addr1;

			if (!quiet)
				fprintf (stderr, "Waiting for the device to reset...");

			libusb_close (dev);
			do {
				sleep (1);
				dev = open_dev (ctx);
				if (dev == NULL) {
					if (!quiet)
						fputc ('.', stderr);
					continue;
				}
				addr2 = libusb_get_device_address (libusb_get_device (dev));
			} while (addr1 == addr2);

			if (!quiet)
				fprintf (stderr, " done.\n");
		} else {
			fprintf (stderr, "Bad argument: %s\n", argv[i]);
			goto err_close;
		}
	}

	status = EXIT_SUCCESS;
	goto err_close;
err_fd:
	close(fd);
err_close:
	libusb_close (dev);
err_exit:
	libusb_exit (ctx);

	return status;
}
