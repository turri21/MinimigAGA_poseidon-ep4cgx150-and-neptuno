#include "errors.h"
#include "hardware.h"
#include "mmc.h"
#include "fat.h"
#include "osd.h"
#include "fpga.h"
#include "fdd.h"
#include "hdd.h"
#include "firmware.h"
#include "menu.h"
#include "config.h"
#include "spi.h"

#include "hexdump.h"

#include <stdio.h>
#include <string.h>

configTYPE config;
fileTYPE file;
extern char s[40];
char configfilename[12];
char DebugMode=0;


int minimig_v1()
{
	return(0);
}


unsigned char romkey[3072];

RAFile romfile;

static char filename[12];

void ClearKickstartMirrorE0(void)
{
  int i;
  spi_osd_cmd32le_cont(OSD_CMD_WR, 0x00e00000);
  for (i = 0; i < (0x80000 / 4); i++) {
    SPI(0x00);
    SPI(0x00);
    SPIN; SPIN; SPIN; SPIN;
    SPI(0x00);
    SPI(0x00);
    SPIN; SPIN; SPIN; SPIN;
  }
  DisableOsd();
  SPIN; SPIN; SPIN; SPIN;
}

void ClearVectorTable(void)
{
  int i;
  spi_osd_cmd32le_cont(OSD_CMD_WR, 0x00000000);
  for (i = 0; i < 256; i++) {
    SPI(0x00);
    SPI(0x00);
    SPIN; SPIN; SPIN; SPIN;
    SPI(0x00);
    SPI(0x00);
    SPIN; SPIN; SPIN; SPIN;
  }
  DisableOsd();
  SPIN; SPIN; SPIN; SPIN;
}

//// UploadKickstart() ////
char UploadKickstart(char *name)
{
	int keysize=0;
	char filename[12];

	strncpy(filename, name, 8); // copy base name
	strcpy(&filename[8], "ROM"); // add extension

	BootPrint("Checking for Amiga Forever key file:");
	if(FileOpen(&file,"ROM     KEY")) {
		keysize=file.size;
		if(file.size<sizeof(romkey)) {
			int c=0;
			while(c<keysize) {
				FileRead(&file, &romkey[c]);
				c+=512;
				FileNextSector(&file);
			}
		} else {
			SetError(ERROR_ROM,"ROM Key file wrong size",file.size,0);
		}
	}

	if (RAOpen(&romfile, filename)) {
		ClearError(ERROR_FILESYSTEM);
		if ((romfile.size & 0xf) == 0xb && !keysize) {
			FatalError(ERROR_ROM,"ROM requires key file",0,0);
		}
		else if (romfile.size == 0x100000) {
			// 1MB Kickstart ROM
			BootPrint("Uploading 1MB Kickstart ...");
			SendFileV2(&romfile, NULL, 0, 0xe00000, romfile.size>>10);
			SendFileV2(&romfile, NULL, 0, 0xf80000, romfile.size>>10);
			ClearVectorTable();
			return(1);
		} else if(romfile.size == 0x80000) {
		// 512KB Kickstart ROM
			SendFileV2(&romfile, NULL, 0, 0xf80000, romfile.size>>9);
			RAOpen(&romfile, filename);
			SendFileV2(&romfile, NULL, 0, 0xe00000, romfile.size>>9);
			ClearVectorTable();
		return(1);
		} else if ((romfile.size == 0x8000b)) {
			// 512KB Kickstart ROM
			SendFileV2(&romfile, romkey, keysize, 0xf80000, romfile.size>>9);
			RAOpen(&romfile, filename);
			SendFileV2(&romfile, romkey, keysize, 0xe00000, romfile.size>>9);
			ClearVectorTable();
			return(1);
		} else if (romfile.size == 0x40000) {
			// 256KB Kickstart ROM
			SendFileV2(&romfile, NULL, 0, 0xf80000, romfile.size>>9);
			RAOpen(&romfile, filename);
			SendFileV2(&romfile, NULL, 0, 0xfc0000, romfile.size>>9);
			ClearVectorTable();
			ClearKickstartMirrorE0();
			return(1);
		} else if ((romfile.size == 0x4000b)) {
			// 256KB Kickstart ROM
			SendFileV2(&romfile, romkey, keysize, 0xf80000, romfile.size>>9);
			RAOpen(&romfile, filename);
			SendFileV2(&romfile, romkey, keysize, 0xfc0000, romfile.size>>9);
			ClearVectorTable();
			ClearKickstartMirrorE0();
			return(1);
		} else {
			FatalError(ERROR_ROM,"ROM size incorrect",romfile.size,0);
		}
	} else {
		FatalError(ERROR_ROM,"ROM missing",0,0);
	}
	return(0);
}

//// UploadActionReplay() ////
char UploadActionReplay()
{
#if 0
  if(minimig_v1()) {
    if (RAOpen(&romfile, "AR3     ROM")) {
      if (romfile.file.size == 0x40000) {
        // 256 KB Action Replay 3 ROM
        BootPrint("\nUploading Action Replay ROM...");
        PrepareBootUpload(0x40, 0x04);
        SendFile(&romfile);
        ClearMemory(0x440000, 0x40000);
        return(1);
      } else {
        BootPrint("\nUnsupported AR3.ROM file size!!!");
        /* FatalError(6); */
        return(0);
      }
    }
  } else {
#endif
    if (RAOpen(&romfile, "HRTMON  ROM")) {
      int adr, data;
      puts("Uploading HRTmon ROM... ");
      SendFileV2(&romfile, NULL, 0, 0xa10000, (romfile.file.size+511)>>9);
      // HRTmon config
      adr = 0xa10000 + 20;
      spi_osd_cmd32le_cont(OSD_CMD_WR, adr);
      data = 0x00800000; // mon_size, 4 bytes
      SPI((data>>24)&0xff); SPI((data>>16)&0xff); SPIN; SPIN; SPIN; SPIN; SPI((data>>8)&0xff); SPI((data>>0)&0xff);
      data = 0x00; // col0h, 1 byte
      SPI((data>>0)&0xff);
      data = 0x5a; // col0l, 1 byte
      SPI((data>>0)&0xff);
      SPIN; SPIN; SPIN; SPIN;
      data = 0x0f; // col1h, 1 byte
      SPI((data>>0)&0xff);
      data = 0xff; // col1l, 1 byte
      SPI((data>>0)&0xff);
      SPIN; SPIN; SPIN; SPIN;
      data = 0xff; // right, 1 byte
      SPI((data>>0)&0xff);
      SPIN; SPIN; SPIN; SPIN;
      data = 0x00; // keyboard, 1 byte
      SPI((data>>0)&0xff);
      SPIN; SPIN; SPIN; SPIN;
      data = 0xff; // key, 1 byte
      SPI((data>>0)&0xff);
      SPIN; SPIN; SPIN; SPIN;
      data = config.enable_ide ? 0xff : 0; // ide, 1 byte
      SPI((data>>0)&0xff);
      SPIN; SPIN; SPIN; SPIN;
      data = 0xff; // a1200, 1 byte
      SPI((data>>0)&0xff);
      SPIN; SPIN; SPIN; SPIN;
      data = config.chipset&CONFIG_AGA ? 0xff : 0; // aga, 1 byte
      SPI((data>>0)&0xff);
      SPIN; SPIN; SPIN; SPIN;
      data = 0xff; // insert, 1 byte
      SPI((data>>0)&0xff);
      SPIN; SPIN; SPIN; SPIN;
      data = 0x0f; // delay, 1 byte
      SPI((data>>0)&0xff);
      SPIN; SPIN; SPIN; SPIN;
      data = 0xff; // lview, 1 byte
      SPI((data>>0)&0xff);
      SPIN; SPIN; SPIN; SPIN;
      data = 0x00; // cd32, 1 byte
      SPI((data>>0)&0xff);
      SPIN; SPIN; SPIN; SPIN;
      data = config.chipset&CONFIG_NTSC ? 1 : 0; // screenmode, 1 byte
      SPI((data>>0)&0xff);
      SPIN; SPIN; SPIN; SPIN;
      data = 0xff; // novbr, 1 byte
      SPI((data>>0)&0xff);
      SPIN; SPIN; SPIN; SPIN;
      data = 0; // entered, 1 byte
      SPI((data>>0)&0xff);
      SPIN; SPIN; SPIN; SPIN;
      data = 1; // hexmode, 1 byte
      SPI((data>>0)&0xff);
      SPIN; SPIN; SPIN; SPIN;
      DisableOsd();
      SPIN; SPIN; SPIN; SPIN;
      adr = 0xa10000 + 68;
      spi_osd_cmd32le_cont(OSD_CMD_WR, adr);
      data = ((config.memory&0x3) + 1) * 512 * 1024; // maxchip, 4 bytes TODO is this correct?
      SPI((data>>24)&0xff); SPI((data>>16)&0xff); SPIN; SPIN; SPIN; SPIN; SPI((data>>8)&0xff); SPI((data>>0)&0xff);
      SPIN; SPIN; SPIN; SPIN;
      DisableOsd();
      SPIN; SPIN; SPIN; SPIN;
      return(1);
    } else {
	  ClearError(ERROR_FILESYSTEM);
      puts("\rhrtmon.rom not found!\r");
      return(0);
    }
  return(0);
}


void SetConfigurationFilename(int config)
{
	if(config)
		sprintf(configfilename,"MINMGAA%dCFG",config);
	else
		strcpy(configfilename,"MINMGAA CFG");
}



unsigned char ConfigurationExists(char *filename)
{
	if(!filename)
		filename=configfilename;	// Use slot-based filename if none provided.
    if (FileOpen(&file, filename))
    {
		return(1);
	}
	ClearError(ERROR_FILESYSTEM);
	return(0);
}


unsigned char LoadConfiguration(char *filename)
{
    static const char config_id[] = "MNMGCFGA"; /* New signature for AGA core */
	int updatekickstart=0;
	int result=0;
    unsigned int key;

	if(!filename)
		filename=configfilename;	// Use slot-based filename if none provided.

    // load configuration data
    if (FileOpen(&file, filename))
    {
		BootPrint("Opened configuration file\n");
        printf("Configuration file size: %lu\r", file.size);
        if (file.size == sizeof(config))
        {
            FileRead(&file, sector_buffer);

			configTYPE *tmpconf=(configTYPE *)&sector_buffer;

            // check file id and version
            if (strncmp(tmpconf->id, config_id, sizeof(config.id)) == 0)
            {
				// A few more sanity checks...
				if(tmpconf->floppy.drives<=4) 
				{
					// If either the old config and new config have a different kickstart file,
					// or this is the first boot, we need to upload a kickstart image.
					if(strncmp(tmpconf->kickstart.name,config.kickstart.name,8)!=0)
						updatekickstart=true;
	                memcpy((void*)&config, (void*)sector_buffer, sizeof(config));
					result=1; // We successfully loaded the config.
				}
				else
					BootPrint("Config file sanity check failed!\n");
            }
            else
                BootPrint("Wrong configuration file format!\n");
        }
    }
    if(!result)
	{
        BootPrint("Config loading failed - using defaults\n");
		ClearError(ERROR_FILESYSTEM);
		// set default configuration
		memset((void*)&config, 0, sizeof(config));	// Finally found default config bug - params were reversed!
		strncpy(config.id, config_id, sizeof(config.id));
		strncpy(config.kickstart.name, "KICK    ", sizeof(config.kickstart.name));
		config.misc = 1<<(PLATFORM_SCANDOUBLER);  // platform register - enable scandoubler by default
		config.kickstart.long_name[0] = 0;
		config.memory = 0x15;
		config.cpu = 0;
		config.chipset = 0;
		config.floppy.speed=CONFIG_FLOPPY2X;
		config.floppy.drives=1;
		config.enable_ide=0;
		config.hardfile[0].enabled = 1;
		strncpy(config.hardfile[0].name, "HARDFILE", sizeof(config.hardfile[0].name));
		config.hardfile[0].long_name[0]=0;
		strncpy(config.hardfile[1].name, "HARDFILE", sizeof(config.hardfile[1].name));
		config.hardfile[1].long_name[0]=0;
		config.hardfile[1].enabled = 2;	// Default is access to entire SD card
		updatekickstart=true;

		BootPrint("Defaults set\n");
	}

    return(result);
}


void ApplyConfiguration(char reloadkickstart)
{
	int rstval=0;

	// Whether or not we uploaded a kickstart image we now need to set various parameters from the config.

  	if(OpenHardfile(0))
	{
		switch(hdf[0].type) // Customise message for SD card access
		{
			case (HDF_FILE | HDF_SYNTHRDB):
		        sprintf(s, "\nHardfile 1 (with fake RDB): %.8s.%.3s", hdf[1].file.name, &hdf[1].file.name[8]);
				break;
			case HDF_FILE:
		        sprintf(s, "\nHardfile 0: %.8s.%.3s", hdf[0].file.name, &hdf[0].file.name[8]);
				break;
			case HDF_CARD:
		        sprintf(s, "\nHardfile 0: using entire SD card");
				break;
			default:
		        sprintf(s, "\nHardfile 0: using SD card partition %d",hdf[0].type-HDF_CARD);	// Number from 1
				break;
		}
        BootPrint(s);
        sprintf(s, "CHS: %u.%u.%u", hdf[0].cylinders, hdf[0].heads, hdf[0].sectors);
        BootPrint(s);
        sprintf(s, "Size: %lu MB", ((((unsigned long) hdf[0].cylinders) * hdf[0].heads * hdf[0].sectors) >> 11));
        BootPrint(s);
        sprintf(s, "Offset: %ld", hdf[0].offset);
		BootPrint(s);
	}
   	if(OpenHardfile(1))
	{
		switch(hdf[1].type)
		{
			case (HDF_FILE | HDF_SYNTHRDB):
		        sprintf(s, "\nHardfile 1 (with fake RDB): %.8s.%.3s", hdf[1].file.name, &hdf[1].file.name[8]);
				break;
			case HDF_FILE:
		        sprintf(s, "\nHardfile 1: %.8s.%.3s", hdf[1].file.name, &hdf[1].file.name[8]);
				break;
			case HDF_CARD:
		        sprintf(s, "\nHardfile 1: using entire SD card");
				break;
			default:
		        sprintf(s, "\nHardfile 1: using SD card partition %d",hdf[1].type-HDF_CARD);	// Number from 1
				break;
		}
        BootPrint(s);
        sprintf(s, "CHS: %u.%u.%u", hdf[1].cylinders, hdf[1].heads, hdf[1].sectors);
        BootPrint(s);
        sprintf(s, "Size: %lu MB", ((((unsigned long) hdf[1].cylinders) * hdf[1].heads * hdf[1].sectors) >> 11));
        BootPrint(s);
        sprintf(s, "Offset: %ld", hdf[1].offset);
        BootPrint(s);
	}

    ConfigIDE(config.enable_ide, config.hardfile[0].present && config.hardfile[0].enabled,
		config.hardfile[1].present && config.hardfile[1].enabled);
#if 0
    sprintf(s, "CPU clock     : %s", config.chipset & 0x01 ? "turbo" : "normal");
    BootPrint(s);
    sprintf(s, "Chip RAM size : %s", config_memory_chip_msg[config.memory & 0x03]);
    BootPrint(s);
    sprintf(s, "Slow RAM size : %s", config_memory_slow_msg[config.memory >> 2 & 0x03]);
    BootPrint(s);

    sprintf(s, "Floppy drives : %u", config.floppy.drives + 1);
    BootPrint(s);
    sprintf(s, "Floppy speed  : %s", config.floppy.speed ? "fast": "normal");
    BootPrint(s);

    BootPrint("");

    sprintf(s, "\nA600 IDE HDC is %s.", config.enable_ide ? "enabled" : "disabled");
    BootPrint(s);
    sprintf(s, "Master HDD is %s.", config.hardfile[0].present ? config.hardfile[0].enabled ? "enabled" : "disabled" : "not present");
    BootPrint(s);
    sprintf(s, "Slave HDD is %s.", config.hardfile[1].present ? config.hardfile[1].enabled ? "enabled" : "disabled" : "not present");
    BootPrint(s);
#endif
#if 0
    if (cluster_size < 64)
    {
        BootPrint("\n***************************************************");
        BootPrint(  "*  It's recommended to reformat your memory card  *");
        BootPrint(  "*   using 32 KB clusters to improve performance   *");
		BootPrint(  "*           when using large hardfiles.           *");	// AMR
        BootPrint(  "***************************************************");
    }
    printf("Bootloading is complete.\r");
#endif

    ConfigCPU(config.cpu);
    ConfigMemory(config.memory);
    ConfigChipset(config.chipset);
    ConfigFloppy(config.floppy.drives, config.floppy.speed);
    ConfigVideo(config.filter.hires, config.filter.lores, config.scanlines);
    ConfigMisc(config.misc);

    if(reloadkickstart) {
		WaitTimer(1000);
		EnableOsd();
		SPI(OSD_CMD_RST);
		rstval |= (SPI_RST_CPU | SPI_CPU_HLT);
		SPI(rstval);
		DisableOsd();
		SPIN; SPIN; SPIN; SPIN;
		UploadActionReplay();
		if (!UploadKickstart(config.kickstart.name)) {
			strcpy(config.kickstart.name, "KICK    ");
			UploadKickstart(config.kickstart.name);
		}
    }
}


unsigned char SaveConfiguration(char *filename)
{
	if(!filename)
		filename=configfilename;	// Use slot-based filename if none provided.

    // save configuration data
    if (FileOpen(&file, filename))
    {
        if (file.size != sizeof(config))
        {
            file.size = sizeof(config);
            if (!UpdateEntry(&file))
                return(0);
        }

        memset((void*)&sector_buffer, 0, sizeof(sector_buffer));
        memcpy((void*)&sector_buffer, (void*)&config, sizeof(config));
        FileWrite(&file, sector_buffer);
        return(1);
    }
    else
    {
		ClearError(ERROR_FILESYSTEM);
        printf("Configuration file not found!\r");
        printf("Trying to create a new one...\r");
        strncpy(file.name, filename, 11);
        file.attributes = 0;
        file.size = sizeof(config);
        printf("Config size is %x (%x) - address is %x\n",sizeof(config),file.size,&config);
        if (FileCreate(0, &file))
        {
            printf("File created.\r");
            printf("Trying to write new data...\r");
            memset((void*)sector_buffer, 0, sizeof(sector_buffer));
            memcpy((void*)sector_buffer, (void*)&config, sizeof(config));

            if (FileWrite(&file, sector_buffer))
            {
                printf("File written successfully.\r");
                return(1);
            }
            else
                printf("File write failed!\r");
        }
        else
            printf("File creation failed!\r");
    }
    return(0);
}

