
# Network Scanner Service

## Description

The Network Scanner Service is designed to scan the local network every 5 minutes to detect all devices connected through the current router. It logs each device's MAC address and hostname (if resolvable) to uniquely named files for efficient tracking and monitoring. This service is useful for network administrators who need ongoing visibility into which devices are on their network.

## Features

- Scans the local network every 5 minutes.
- Logs are written to MAC address and hostname-based files.
- Each log entry is timestamped for audit and tracking purposes.
- Syncs all log files to an AWS S3-compatible bucket using `rclone`.
- Service runs as a systemd unit, allowing for easy management through standard systemd commands.

## Installation

1. **Install Required Tools:**
   Ensure `arp-scan`, `dig` (from dnsutils), and `rclone` are installed:
   ```bash
   sudo apt-get update
   sudo apt-get install arp-scan dnsutils
   sudo apt install rclone
   ```

2. **Configure `rclone`:**
   Set up `rclone` with your cloud storage provider:
   ```bash
   rclone config
   ```
   Follow the interactive prompt to add your S3-compatible storage.

3. **Script Setup:**
   Place the script in a desired directory, for example, `/home/pi/scan/scan.sh`.

4. **Set Permissions:**
   Make sure the script is executable:
   ```bash
   chmod +x /home/pi/scan/scan.sh
   ```

5. **Create Systemd Service:**
   Create a file named `networkscanner.service` in `/etc/systemd/system/` and populate it with the provided service configuration.

   ```ini
   [Unit]
   Description=Network Scanner Service
   Wants=network-online.target
   After=network-online.target
   
   [Service]
   Type=simple
   User=pi
   ExecStart=/bin/bash /home/pi/scan/scan.sh
   Restart=on-failure
   RestartSec=5s
   
   [Install]
   WantedBy=multi-user.target
   ```

## Usage

- **Start the Service:**
  ```bash
  sudo systemctl start networkscanner.service
  ```

- **Stop the Service:**
  ```bash
  sudo systemctl stop networkscanner.service
  ```

- **Enable Service on Boot:**
  ```bash
  sudo systemctl enable networkscanner.service
  ```

- **Check Service Status:**
  ```bash
  sudo systemctl status networkscanner.service
  ```

## Maintenance

- **Log Rotation:**
  Logs can grow over time; set up log rotation with `logrotate` to manage log size and retention.

- **Monitoring Service Health:**
  Regularly check the service status and logs for any errors or unusual activities. This can be automated with monitoring tools or scripts that alert you to any service disruptions.

- **Updating Scripts and Tools:**
  Keep `arp-scan`, `dnsutils`, and `rclone` updated to ensure compatibility and security:
  ```bash
  sudo apt-get update
  sudo apt-get upgrade arp-scan dnsutils
  ```

## Troubleshooting

- **Common Issues:**
  - Permissions errors during scanning can often be resolved by ensuring the script is run with sufficient privileges.
  - If `rclone` fails to sync files, verify your cloud storage configuration and network connectivity.

For more detailed troubleshooting, refer to the specific tool documentation or the system logs for error messages.

## License

This project is licensed under the [MIT License](LICENSE).
