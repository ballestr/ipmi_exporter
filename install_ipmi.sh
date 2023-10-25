#!/bin/sh
install -m 0744 ipmisensors.sh /usr/local/bin/
install -m 0644 prometheus-ipmi-exporter.service /etc/systemd/system/

systemctl daemon-reload
systemctl enable  prometheus-ipmi-exporter.*
systemctl restart prometheus-ipmi-exporter.*
systemctl status  prometheus-ipmi-exporter.*
