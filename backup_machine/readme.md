# backup-machine.cmd

Captures a whole disk and streams it to google drive as a means of simple backup.

## setup

* rclone -> download and put into folder /rclone
  * https://rclone.org/drive/
* wimlib -> download and put into folder /wimlib
  * https://wimlib.net/
* rclone config
  * set up google drive config
  * copy rclone.conf into this folder

## how does it work

- First connect to your google drive using ```rclone config```. This creates a config file  
```rclone.conf``` (usually hidden in %appdata%\rclone folder) with credentials to connect to google drive. 
- copy the rclone.conf into this folder, the script expects it here (or remove the --config line inside)
- start the script
- it tries to elevate you to admin rights - if you grant it
- using wimlib it reads a disk drive (or path), configured inside the script
  - usually this is a .wim file, but can also be streamed
- this then directly streams this capture to google drive, bypassing a local copy of the disk image
- Output is a .pwim file, a piped windows image file. Somewhat not compatible with the original windows 
tools, but perfectly fine for wimlib.

If you want the whole script summarized:

```
wimlib-imagex capture C:\ - "Backup" --snapshot | rclone rcat gdrive:backups/backup-%DATE%.pwim
```

This backups a whole hard disk and stores it on google drive - without all the setup
and config code.
