# SNMP Scanner

A simple Bash script to check SNMP port 161 UDP and perform SNMP walks on multiple targets with colored output, progress tracking, and consolidated results.

## Features

- 🎯 **Bulk SNMP Scanning**: Scan multiple IP addresses from a file
- 🎨 **Colored Output**: Enhanced visual feedback with color-coded messages
- 📊 **Progress Tracking**: Real-time progress with current/total target counts
- 📁 **Consolidated Results**: All scan results saved in a single organized file
- ⏱️ **Timeout Protection**: Built-in timeouts prevent hanging scans
- 🛑 **Graceful Interruption**: Stop scans anytime with Ctrl+C while preserving results
- 📈 **Success Rate Calculation**: Automatic calculation and color-coded success rates
- 🔧 **Flexible Configuration**: Customizable community strings, OIDs, and output files

## Requirements

- **nmap**: For port scanning (`sudo apt install nmap` or `yum install nmap`)
- **snmp-utils**: For SNMP operations (`sudo apt install snmp` or `yum install net-snmp-utils`)
- **Bash**: Version 4.0 or higher
- **Root/sudo privileges**: Required for UDP port scanning with nmap

## Installation

1. Download the script:
```bash
wget https://your-repo.com/snmp_scanner.sh
# or
curl -O https://your-repo.com/snmp_scanner.sh
```

2. Make it executable:
```bash
chmod +x snmp_scanner.sh
```

## Usage

### Basic Usage
```bash
./snmp_scanner.sh -f targets.txt
```

### Advanced Usage
```bash
./snmp_scanner.sh -f targets.txt -c private -o 1.3.6.1.2.1.2 -r custom_results.txt
```

### Command Line Options

| Option | Description | Default | Required |
|--------|-------------|---------|----------|
| `-f` | Input file containing target IP addresses | - | ✅ |
| `-c` | SNMP community string | `public` | ❌ |
| `-o` | OID to query | `1.3.6.1.2.1.1` (System Info) | ❌ |
| `-r` | Results output file name | `snmp_results.txt` | ❌ |
| `-h` | Show help message and exit | - | ❌ |

### Input File Format

Create a text file with one IP address per line:

```
192.168.1.1
192.168.1.100
10.0.0.1
172.16.1.50
# This is a comment - will be ignored
192.168.2.1
```

**Note**: Empty lines and lines starting with `#` are automatically skipped.

## Examples

### Example 1: Basic System Information Scan
```bash
./snmp_scanner.sh -f network_devices.txt
```

### Example 2: Interface Information with Custom Community
```bash
./snmp_scanner.sh -f switches.txt -c private -o 1.3.6.1.2.1.2
```

### Example 3: Custom Output File
```bash
./snmp_scanner.sh -f routers.txt -c community123 -r router_scan_results.txt
```

### Example 4: Scanning for Specific Hardware Info
```bash
./snmp_scanner.sh -f targets.txt -o 1.3.6.1.2.1.1.1.0 -r hardware_info.txt
```

## Common OIDs

| OID | Description |
|-----|-------------|
| `1.3.6.1.2.1.1` | System Information (default) |
| `1.3.6.1.2.1.1.1.0` | System Description |
| `1.3.6.1.2.1.1.3.0` | System Uptime |
| `1.3.6.1.2.1.1.5.0` | System Name |
| `1.3.6.1.2.1.2` | Interface Information |
| `1.3.6.1.2.1.25.1.1.0` | System Processes |

## Output

### Console Output
The script provides real-time colored feedback:

- 🔵 **Blue [*]**: Status messages and progress
- 🟢 **Green [+]**: Success messages
- 🔴 **Red [-]**: Error messages
- 🟡 **Yellow [!]**: Warning messages
- 🟦 **Cyan [i]**: Information messages

### Results File Structure
```
================================================
SNMP Scan Results - Mon Dec 4 14:30:25 UTC 2023
================================================
Community String: public
OID Queried: 1.3.6.1.2.1.1
Source File: targets.txt
================================================

----------------------------------------
Target: 192.168.1.1
Scan Time: Mon Dec 4 14:30:25 UTC 2023
----------------------------------------
SNMPv2-MIB::sysDescr.0 = STRING: Linux router 4.15.0
SNMPv2-MIB::sysObjectID.0 = OID: NET-SNMP-MIB::netSnmpAgentOIDs.10
Status: SUCCESS - Data retrieved

----------------------------------------
Target: 192.168.1.100
Scan Time: Mon Dec 4 14:30:35 UTC 2023
----------------------------------------
Status: UNREACHABLE - Port 161/udp closed or filtered

================================================
SCAN SUMMARY
================================================
Total Targets Scanned: 10
Successful SNMP Walks: 7
Failed SNMP Walks: 1
Unreachable Targets: 2
Scan Completed: Mon Dec 4 14:35:42 UTC 2023
================================================
```

## Interrupting Scans

You can safely interrupt the scan at any time:

1. Press `Ctrl+C` during execution
2. The script will complete the current target check
3. Partial results will be saved to the output file
4. An interruption summary will be added to show progress

## Troubleshooting

### Permission Issues
```bash
# If you get permission errors, run with sudo
sudo ./snmp_scanner.sh -f targets.txt
```

### Missing Dependencies
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nmap snmp

# CentOS/RHEL/Fedora
sudo yum install nmap net-snmp-utils
# or for newer versions
sudo dnf install nmap net-snmp-utils
```

### Timeout Issues
If scans are taking too long:
- Check if targets are actually reachable
- Verify SNMP is enabled on target devices
- Try different community strings
- Ensure firewall allows UDP/161 traffic

### No Results
If SNMP walks return no data:
- Verify the community string is correct
- Check if SNMP is configured on target devices
- Try SNMPv1 instead of v2c (modify script if needed)
- Ensure the OID exists on target devices

## Performance Considerations

- **Network Speed**: Scanning over slow networks will take longer
- **Target Count**: Large target lists will require more time
- **Timeouts**: Default timeouts are 10s for port checks, 30s for SNMP walks
- **Parallel Execution**: Currently processes targets sequentially for reliability

## Security Notes

- Always use appropriate SNMP community strings
- Be aware that SNMP communities are transmitted in plain text
- Ensure you have permission to scan target networks
- Consider using SNMPv3 for sensitive environments (requires script modification)

## Contributing

Feel free to submit issues, feature requests, or pull requests to improve the script.

## License

This script is provided as-is under the MIT License. Use at your own risk.

## Changelog

### v1.1
- Added colored output and progress tracking
- Implemented graceful interruption handling
- Added consolidated results in single file
- Improved error handling and timeouts
- Added success rate calculations

### v1.0
- Initial release with basic SNMP scanning functionality
