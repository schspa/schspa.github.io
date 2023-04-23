#!/usr/bin/env bash

cat << 'EOF' > /usr/local/bin/pve-guest-monitor.sh
#!/usr/bin/env bash

vmid=100

while true; do
        active_count=$(/usr/sbin/qm list | grep running | wc -l)
        if [[ $active_count -gt 0 ]]; then
                # inhibit host sleep
                systemd-inhibit --what=sleep \
                                --who="Proxmox Guest" \
                                --why="Guest VM is running" \
                                sleep 30
        fi
        # wait for 1 second before checking againe
        sleep 1
done

EOF

chmod a+x /usr/local/bin/pve-guest-monitor.sh

cat << 'EOF' > /etc/systemd/system/pve-guest-prevent-sleep.service
[Unit]
Description=PVE guest status monitor
After=network.target

[Service]
ExecStart=/usr/local/bin/pve-guest-monitor.sh
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl restart pve-guest-prevent-sleep.service
systemctl enable pve-guest-prevent-sleep.service
systemctl status pve-guest-prevent-sleep.service
