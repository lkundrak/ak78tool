#!/bin/bash

set -e
set -o pipefail

reg ()
{
	V=$(./ak78tool upload $1 4 /dev/stdout |xxd -e |awk '{print "0x"$2}')
	[ "$V" ]
	if [ "$3" ]
	then
		printf "%s %s  %-25s# %s\\n" $1 $V $2 "$3"
	else
		printf "%s %s  %s\\n" $1 $V $2
	fi
}

echo "Chip ID register"
reg 0x08000000      CHIP_ID                 "Chip ID register"

echo
echo "System control registers"
reg 0x08000004      CLK_DIV1                "Clock divider register 1"
reg 0x08000008      CLK_DIV2                "Clock divider register 2"
reg 0x0800000C      CLK_CON                 "Clock control and soft rest control register"
reg 0x080000DC      N_CON                   "N configuration register"
reg 0x08000058      MULFUN_CON              "Multiple function control register"

reg 0x08000034      IRQ_MASK                "Interrupt mask register for IRQ"
reg 0x08000038      FIQ_MASK                "Interrupt mask register for FIQ"
reg 0x080000CC      INT_STAT                "Interrupt status register"
reg 0x0800004C      INT_STATEN              "Interrupt Enable/status register of system control module"

reg 0x0800003C      WKUPGPIO_POL            "Wake-up GPIO polarity selection"
reg 0x08000040      WKUPGPIO_CLR            "Clear wake-up GPIO status"
reg 0x08000044      WKUPGPIO_EN             "Enabling the wake-up function of corresponding wake-up GPIOS"
reg 0x08000048      WKUPGPIO_STAT           "Wake-up GPIO status register, displaying current wake-up GPIO status"

reg 0x08000050      RTCUSB_CON              "RTC configuratio and USB control register"
reg 0x08000054      RTC_BOOTMOD             "RTC read back and bootup mode register"

echo
echo "Timers"
reg 0x08000018      TIMER1_CON
reg 0x0800001C      TIMER2_CON
reg 0x08000020      TIMER3_CON
reg 0x08000024      TIMER4_CON
reg 0x08000028      TIMER5_CON
reg 0x08000100      TIMER1_RDBACK
reg 0x08000104      TIMER2_RDBACK
reg 0x08000108      TIMER3_RDBACK
reg 0x0800010C      TIMER4_RDBACK
reg 0x08000110      TIMER5_RDBACK

echo
echo "Analog control"
reg 0x0800005C      ANALOG_CON1
reg 0x08000060      ADC1_CON
reg 0x08000064      ANALOG_CON2
reg 0x08000068      TS_XVAL
reg 0x0800006C      TS_YVAL
reg 0x08000070      ADC1_STAT
echo
echo "Analog control"
reg 0x20072000      ADC2_CON
reg 0x20072004      ADC2_DAT

reg 0x08000078      SHAREPIN_CON1           "Shared-pin control register 1"
reg 0x08000074      SHAREPIN_CON2           "Shared-pin control register 2"
reg 0x0800009C      PPU_PPD1                "Programmable Pull-ups/Pull-downs register 1"
reg 0x080000A0      PPU_PPD2                "Programmable Pull-ups/Pull-downs register 2"
reg 0x080000A4      PPU_PPD3                "Programmable Pull-ups/Pull-downs register 3"
reg 0x080000A8      PPU_PPD4                "Programmable Pull-ups/Pull-downs register 4"

echo
echo "CRC"
reg 0x080000AC      CRC_POLYLEN             "Polynomial's length and start CRC"
reg 0x080000B0      CRC_COEFCON             "Coefficient configuration"
reg 0x080000D0      CRC_RESULT              "CRC result"
reg 0x080000D4      IO_CON1                 "IO control register 1"
reg 0x080000D8      IO_CON2                 "IO control register 2"

echo
echo "PWM"
reg 0x0800002C      PWM1_CON
reg 0x08000030      PWM2_CON
reg 0x080000B4      PWM3_CON
reg 0x080000B8      PWM4_CON

echo
echo "GPIOS"
reg 0x0800007C      GPIO_DIR1
reg 0x08000084      GPIO_DIR2
reg 0x0800008C      GPIO_DIR3
reg 0x08000094      GPIO_DIR4
reg 0x08000080      GPIO_OUT1
reg 0x08000088      GPIO_OUT2
reg 0x08000090      GPIO_OUT3
reg 0x08000098      GPIO_OUT4
reg 0x080000BC      GPIO_IN1
reg 0x080000C0      GPIO_IN2
reg 0x080000C4      GPIO_IN3
reg 0x080000C8      GPIO_IN4
reg 0x080000E0      GPIO_INT1
reg 0x080000E4      GPIO_INT2
reg 0x080000E8      GPIO_INT3
reg 0x080000EC      GPIO_INT4
reg 0x080000F0      GPIO_INTPOL1
reg 0x080000F4      GPIO_INTPOL2
reg 0x080000F8      GPIO_INTPOL3
reg 0x080000FC      GPIO_INTPOL4

echo
echo "Display controller"
reg 0x20010000      LCD_COMM1               "LCD controller command register 1"
reg 0x20010004      LCD_MPUIFCON            "MPU interface control"
reg 0x20010008      LCD_RSTSIG
reg 0x2001000C      LCD_MPURDBACK
reg 0x20010010      LCD_RGBIFCON1
reg 0x20010014      LCD_RGBIFCON2
reg 0x20010018      LCD_RGBPGSIZE
reg 0x2001001C      LCD_RGBPGOFFSET
reg 0x20010020      LCD_OSDADDR
reg 0x20010024      LCD_OSDOFFSET
reg 0x20010028      LCD_OSDCOLOR1
reg 0x2001002C      LCD_OSDCOLOR2
reg 0x20010030      LCD_OSDCOLOR3
reg 0x20010034      LCD_OSDCOLOR4
reg 0x200100D0      LCD_OSDCOLOR5
reg 0x200100D4      LCD_OSDCOLOR6
reg 0x200100D8      LCD_OSDCOLOR7
reg 0x200100DC      LCD_OSDCOLOR8
reg 0x20010038      LCD_OSDSIZE
reg 0x2001003C      LCD_BACKCOLOR
reg 0x20010040      LCD_RGBIFCON3
reg 0x20010044      LCD_RGBIFCON4
reg 0x20010048      LCD_RGBIFCON5
reg 0x2001004C      LCD_RGBIFCON6
reg 0x20010050      LCD_RGBIFCON7
reg 0x20010054      LCD_RGBIFCON8
reg 0x20010058      LCD_RGBIFCON9
reg 0x2001005C      LCD_Y1_ADDR
reg 0x20010060      LCD_Cb1_ADDR
reg 0x20010064      LCD_Cr1_ADDR
reg 0x20010068      LCD_YCbCr1_HINFO
reg 0x2001006C      LCD_YCbCr1_VINFO
reg 0x20010070      LCD_YCbCr1_SCAL
reg 0x20010074      LCD_YCbCr1_DISPINFO
reg 0x20010078      LCD_YCbCr1_PGSIZE
reg 0x2001007C      LCD_YCbCr1_PGOFFSET
reg 0x20010080      LCD_Y2_ADDR
reg 0x20010084      LCD_Cb2_ADDR
reg 0x20010088      LCD_Cr2_ADDR
reg 0x2001008C      LCD_YCbCr2_HINFO
reg 0x20010090      LCD_YCbCr2_VINFO
reg 0x20010094      LCD_YCbCr2_SCAL
reg 0x20010098      LCD_YCbCr2_DISPINFO
reg 0x200100A8      LCD_RGBOFFSET
reg 0x200100AC      LCD_RGBSIZE
reg 0x200100B0      LCD_DISPSIZE
reg 0x200100B4      LCD_COMM2
reg 0x200100B8      LCD_OP
reg 0x200100BC      LCD_STAT
reg 0x200100C0      LCD_INTEN
reg 0x200100C8      LCD_SOFTCON
reg 0x200100CC      TV_IFCON
reg 0x200100E8      LCD_CLKCON

echo
echo "MMC/SD controller"
reg 0x20020004      SD_CLKCON
reg 0x20020008      SD_COMMARG
reg 0x2002000C      SD_COMM
reg 0x20020010      SD_COMMRESP
reg 0x20020014      SD_RESP1
reg 0x20020018      SD_RESP2
reg 0x2002001C      SD_RESP3
reg 0x20020020      SD_RESP4
reg 0x20020024      SD_DATATIMER
reg 0x20020028      SD_DATALEN
reg 0x2002002C      SD_DATACON
reg 0x20020030      SD_DATACOUNT
reg 0x20020034      SD_STAT
reg 0x20020038      SD_INTEN
reg 0x2002003C      SD_DMAMOD
reg 0x20020040      SD_CPUMOD

echo
echo "SDIO controller"
reg 0x20021004      SDIO_CLKCON
reg 0x20021008      SDIO_COMMARG
reg 0x2002100C      SDIO_COMM
reg 0x20021010      SDIO_COMMRESP
reg 0x20021014      SDIO_RESP1
reg 0x20021018      SDIO_RESP2
reg 0x2002101C      SDIO_RESP3
reg 0x20021020      SDIO_RESP4
reg 0x20021024      SDIO_DATATIMER
reg 0x20021028      SDIO_DATALEN
reg 0x2002102C      SDIO_DATACON
reg 0x20021030      SDIO_DATACOUNT
reg 0x20021034      SDIO_STAT
reg 0x20021038      SDIO_INTEN
reg 0x2002103C      SDIO_DMAMOD
reg 0x20021040      SDIO_CPUMOD

echo
echo "SPI1 SPI2 Controllers"
reg 0x20024000      SPI1_CON
reg 0x20024004      SPI1_STAT
reg 0x20024008      SPI1_INTEN
reg 0x2002400C      SPI1_COUNT
reg 0x20024010      SPI1_TXBUF
reg 0x20024014      SPI1_RXBUF
reg 0x20024018      SPI1_OUTDATA
reg 0x2002401C      SPI1_INDATA
reg 0x20024020      SPI1_TIMEOUT
reg 0x20025000      SPI2_CON
reg 0x20025004      SPI2_STAT
reg 0x20025008      SPI2_INTEN
reg 0x2002500C      SPI2_COUNT
reg 0x20025010      SPI2_TXBUF
reg 0x20025014      SPI2_RXBUF
reg 0x20025018      SPI2_OUTDATA
reg 0x2002501C      SPI2_INDATA
reg 0x20025020      SPI2_TIMEOUT

echo
echo "UART1~UART4 controllers"
reg 0x20026000      UART1_CON1
reg 0x20026004      UART1_CON2
reg 0x20026008      UART1_DATACON
reg 0x2002600C      UART1_TXRXBUF
reg 0x20027000      UART2_CON1
reg 0x20027004      UART2_CON2
reg 0x20027008      UART2_DATACON
reg 0x2002700C      UART2_TXRXBUF
reg 0x20028000      UART3_CON1
reg 0x20028004      UART3_CON2
reg 0x20028008      UART3_DATACON
reg 0x2002800C      UART3_TXRXBUF
reg 0x20029000      UART4_CON1
reg 0x20029004      UART4_CON2
reg 0x20029008      UART4_DATACON
reg 0x2002900C      UART4_TXRXBUF

echo
echo "Nand flash controller"
reg 0x2002a100      NFC_COMM1               "Nand flash command register 1"
reg 0x2002a104      NFC_COMM2               "Nand flash command register 2"
reg 0x2002a108      NFC_COMM3               "Nand flash command register 3"
reg 0x2002a10C      NFC_COMM4               "Nand flash command register 4"
reg 0x2002a110      NFC_COMM5               "Nand flash command register 5"
reg 0x2002a114      NFC_COMM6               "Nand flash command register 6"
reg 0x2002a118      NFC_COMM7               "Nand flash command register 7"
reg 0x2002a11C      NFC_COMM8               "Nand flash command register 8"
reg 0x2002a120      NFC_COMM9               "Nand flash command register 9"
reg 0x2002a124      NFC_COMM10              "Nand flash command register 10"
reg 0x2002a128      NFC_COMM11              "Nand flash command register 11"
reg 0x2002a12C      NFC_COMM12              "Nand flash command register 12"
reg 0x2002a130      NFC_COMM13              "Nand flash command register 13"
reg 0x2002a134      NFC_COMM14              "Nand flash command register 14"
reg 0x2002a138      NFC_COMM15              "Nand flash command register 15"
reg 0x2002a13C      NFC_COMM16              "Nand flash command register 16"
reg 0x2002a140      NFC_COMM17              "Nand flash command register 17"
reg 0x2002a144      NFC_COMM18              "Nand flash command register 18"
reg 0x2002a148      NFC_COMM19              "Nand flash command register 19"
reg 0x2002a14C      NFC_COMM20              "Nand flash command register 20"
reg 0x2002a150      NFC_STAT1               "Nand flash status register 1"
reg 0x2002a154      NFC_STAT2               "Nand flash status register 2"
reg 0x2002a158      NFC_CONSTAT             "Nand flash control/status register"
reg 0x2002a15C      NFC_COMMLEN             "Nand flash command length"
reg 0x2002a160      NFC_DATALEN             "Nand flash data length"

echo
echo "ECC sub-module controller"
reg 0x2002b000      ECC_CON                 "ECC control register"
reg 0x2002b004      ECC_ERRPOS1             "Error posision register 1"
reg 0x2002b008      ECC_ERRPOS2             "Error posision register 2"
reg 0x2002b00C      ECC_ERRPOS3             "Error posision register 3"
reg 0x2002b010      ECC_ERRPOS4             "Error posision register 4"
reg 0x2002b014      ECC_ERRPOS5             "Error posision register 5"
reg 0x2002b018      ECC_ERRPOS6             "Error posision register 6"
reg 0x2002b01C      ECC_ERRPOS7             "Error posision register 7"
reg 0x2002b020      ECC_ERRPOS8             "Error posision register 8"




echo
echo "L2 controller"
reg 0x2002c000      L2_ADDRBUF0             "DMA address information buffer0~buffer15"
reg 0x2002c004      L2_ADDRBUF1
reg 0x2002c008      L2_ADDRBUF2
reg 0x2002c00C      L2_ADDRBUF3
reg 0x2002c010      L2_ADDRBUF4
reg 0x2002c014      L2_ADDRBUF5
reg 0x2002c018      L2_ADDRBUF6
reg 0x2002c01C      L2_ADDRBUF7
reg 0x2002c020      L2_ADDRBUF8
reg 0x2002c024      L2_ADDRBUF9
reg 0x2002c028      L2_ADDRBUF10
reg 0x2002c02C      L2_ADDRBUF11
reg 0x2002c030      L2_ADDRBUF12
reg 0x2002c034      L2_ADDRBUF13
reg 0x2002c038      L2_ADDRBUF14
reg 0x2002c03C      L2_ADDRBUF15
reg 0x2002c040      L2_CONBUF0              "DMA opeeration times buufer0~buffer15"
reg 0x2002c044      L2_CONBUF1
reg 0x2002c048      L2_CONBUF2
reg 0x2002c04C      L2_CONBUF3
reg 0x2002c050      L2_CONBUF4
reg 0x2002c054      L2_CONBUF5
reg 0x2002c058      L2_CONBUF6
reg 0x2002c05C      L2_CONBUF7
reg 0x2002c060      L2_CONBUF8
reg 0x2002c064      L2_CONBUF9
reg 0x2002c068      L2_CONBUF10
reg 0x2002c06C      L2_CONBUF11
reg 0x2002c070      L2_CONBUF12
reg 0x2002c074      L2_CONBUF13
reg 0x2002c078      L2_CONBUF14
reg 0x2002c07C      L2_CONBUF15
reg 0x2002c080      L2_DMAREQ               "DMA request configuration"
reg 0x2002c084      L2_FRACDMAADDR          "Fraction DMA address information"
reg 0x2002c088      L2_CONBUF0_7            "Buffer0~buffer7 configuration"
reg 0x2002c08C      L2_CONBUF8_15           "CPU-controlled buffer and buffer8~buffer15 configuration"
reg 0x2002c090      L2_BUFASSIGN1           "Buffer assignment"
reg 0x2002c094      L2_BUFASSIGN2           "Buffer assignment"
reg 0x2002c098      L2_LDMACON              "Configuration of LDMA"
reg 0x2002c09C      L2_BUFINTEN             "This register enables/disables the buffer interrupts"
reg 0x2002c0A0      L2_BUFSTAT1             "Buffer status register 1"
reg 0x2002c0A8      L2_BUFSTAT2             "Buffer status register 2"
reg 0x2002c0A4      CRC_CON                 "CRC configuration register"



echo
echo "RAM controller"
reg 0x2002d000      MEM_CON1                "RAM controller configuration register 1"
reg 0x2002d004      MEM_CON2                "RAM controller configuration register 2"
reg 0x2002d008      MEM_CON3                "RAM controller configuration register 3"
reg 0x2002d00C      DMA_PRI1                "DMA priority configuration register 1"
reg 0x2002d010      DMA_PRI2                "DMA priority configuration register 2"
reg 0x2002d014      AHB_PRI                 "AHB priority configuration register"


echo
echo "DAC controller"
reg 0x2002e000      DAC_CON                 "DAC configuration register"
reg 0x2002e004      IIS_CON                 "IIS configuration register"
reg 0x2002e008      DAC_CPUDATA             "Data from CPU"


echo
echo "Camera controller"
reg 0x20030000      CAM_SENSORCOMM          "Image capturing command"
reg 0x20030004      CAM_IMAGEINF1           "Source/destination image horizontal length"
reg 0x20030008      CAM_IMAGEINF2           "Horizontal scalling information"
reg 0x2003000C      CAM_IMAGEINF3           "Source/Destination image vertical length"
reg 0x20030010      CAM_IMAGEINF4           "Horizontal scalling information"
reg 0x20030018      CAM_ODDYADDR            "DMA starting address of external RAM for Y component of odd frame"
reg 0x2003001C      CAM_ODDCbADDR           "DMA starting address of external RAM for Cb component of odd frame"
reg 0x20030020      CAM_ODDCrADDR           "DMA starting address of external RAM for Cr component of odd frame"
reg 0x20030024      CAM_ODDRGBADDR          "DMA starting address of external RAM for RGB/JPGE data of odd frame"
reg 0x20030028      CAM_EVENYADDR
reg 0x2003002C      CAM_EVENCbADDR
reg 0x20030030      CAM_EVENCrADDR
reg 0x20030034      CAM_EVENRGBADDR
reg 0x20030040      CAM_SENSORCON           "Image sensor configuration"
reg 0x20030060      CAM_FRAMESTAT           "Status of the current frame"
reg 0x20030080      CAM_FRAMELINE           "The line number of a frame when the input data is in JPEG-compressed format"
