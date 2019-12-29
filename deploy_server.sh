#!/bin/bash
apt --assume-yes update
apt --assume-yes install lib32gcc1 screen curl wget unzip
useradd -m -s /bin/bash hl2dm
su hl2dm -c "mkdir ~/Steam && cd ~/Steam \
        && curl -qL \"https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz\" | tar zxvf - \
        && ./steamcmd.sh \
                +login anonymous \
                +force_install_dir /home/hl2dm/ \
                +app_update 232370 validate \
                +quit \
        && cd ~ && curl -qLO \"https://github.com/jackharpr/hl2dm-xms/releases/latest/download/linux.zip\" \
        && unzip -o linux.zip \
        && chmod +x hl2mp/addons/sourcemod/data/system2/linux/amd64/7z hl2mp/addons/sourcemod/data/system2/linux/i386/7z \
        && echo -e \"@ShutdownOnFailedCommand 1\n@NoPromptForPassword 1\nlogin anonymous\nforce_install_dir /home/hl2dm\napp_update 232370\nquit\" >> autoupdate \
        && echo \"screen -S hl2dm -d -m ./srcds_run -console -game hl2mp +map dm_lockdown +maxplayers 12 -tickrate 100 -autoupdate -steam_dir /home/hl2dm/Steam -steamcmd_script /home/hl2dm/autoupdate -strictportbind +port 27015 +tv_port 27020 +clientport 27005\" >> start_server.sh && chmod +x start_server.sh \
        && echo \"@reboot /bin/bash /home/hl2dm/start_server.sh\" >> cron && crontab cron && rm cron \
        && rm /home/hl2dm/linux.zip \
        && ./start_server.sh"
echo " "
echo "********************************"
echo "If all went well, your matchserver is now up and running!"
echo "********************************"