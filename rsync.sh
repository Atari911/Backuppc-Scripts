#!/bin/bash

# Assums that the computer is running at backuppc.spohnhome.com
rsync -avz /var/lib/backuppc backuppc@backuppc.spohnhome.com:/var/lib/backuppc

