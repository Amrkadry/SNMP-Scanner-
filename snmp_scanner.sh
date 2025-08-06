#!/bin/bash

# Enhanced SNMP Scanner with colored output and single file results
# Usage: ./snmp_scanner.sh -f <targets_file> [-c <community>] [-o <OID>] [-r <results_file>]

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Default values
COMMUNITY="public"
OID="1.3.6.1.2.1.1"  # System info
RESULTS_FILE="snmp_results.txt"

# Function to print colored messages
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[i]${NC} $1"
}

# Function to print banner
print_banner() {
    echo -e "${PURPLE}"
    echo "================================================"
    echo "          Enhanced SNMP Scanner v1.1"
    echo "================================================"
    echo -e "${NC}"
}

# Function to handle script interruption
cleanup() {
    echo ""
    print_warning "Scan interrupted by user!"
    
    # Add interruption notice to results file if it exists
    if [[ -f "$RESULTS_FILE" ]]; then
        cat >> "$RESULTS_FILE" << EOF

================================================
SCAN INTERRUPTED
================================================
Scan was interrupted at: $(date)
Targets processed: $current_target/$total_targets
Successful scans: $successful_scans
Failed scans: $failed_scans
Unreachable targets: $unreachable_targets
================================================
EOF
        print_info "Partial results saved to: $RESULTS_FILE"
    fi
    
    print_info "Use Ctrl+C again to force exit or wait for cleanup to complete..."
    exit 130
}

# Set up signal handlers for graceful shutdown
trap cleanup SIGINT SIGTERM

# Parse options
while getopts ":f:c:o:r:h" opt; do
  case $opt in
    f) INPUT_FILE="$OPTARG" ;;
    c) COMMUNITY="$OPTARG" ;;
    o) OID="$OPTARG" ;;
    r) RESULTS_FILE="$OPTARG" ;;
    h) 
        echo "Usage: $0 -f <targets_file> [-c <community>] [-o <OID>] [-r <results_file>]"
        echo "Options:"
        echo "  -f  Input file containing target IPs (required)"
        echo "  -c  SNMP community string (default: public)"
        echo "  -o  OID to query (default: 1.3.6.1.2.1.1 - system info)"
        echo "  -r  Results output file (default: snmp_results.txt)"
        echo "  -h  Show this help message"
        exit 0
        ;;
    \?) 
        print_error "Invalid option: -$OPTARG"
        echo "Use -h for help"
        exit 1 
        ;;
    :) 
        print_error "Option -$OPTARG requires an argument."
        exit 1 
        ;;
  esac
done

# Check for required input
if [[ -z "$INPUT_FILE" ]]; then
    print_error "Missing required parameter: input file"
    echo "Usage: $0 -f <targets_file> [-c <community>] [-o <OID>] [-r <results_file>]"
    echo "Use -h for detailed help"
    exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    print_error "File not found: $INPUT_FILE"
    exit 1
fi

# Print banner and scan info
print_banner

print_info "Configuration:"
echo -e "  ${WHITE}Input File:${NC} $INPUT_FILE"
echo -e "  ${WHITE}Community:${NC} $COMMUNITY"
echo -e "  ${WHITE}OID:${NC} $OID"
echo -e "  ${WHITE}Results File:${NC} $RESULTS_FILE"
echo ""

# Initialize results file with header
cat > "$RESULTS_FILE" << EOF
================================================
SNMP Scan Results - $(date)
================================================
Community String: $COMMUNITY
OID Queried: $OID
Source File: $INPUT_FILE
================================================

EOF

# Count total targets
total_targets=$(wc -l < "$INPUT_FILE")
current_target=0
successful_scans=0
failed_scans=0
unreachable_targets=0

print_status "Starting SNMP scan on $total_targets targets..."
print_warning "Press Ctrl+C at any time to stop the scan gracefully"
echo ""

# Process each IP
while IFS= read -r ip; do
    # Skip empty lines and comments
    [[ -z "$ip" || "$ip" =~ ^[[:space:]]*# ]] && continue
    
    current_target=$((current_target + 1))
    
    print_status "[$current_target/$total_targets] Scanning $ip for SNMP access..."
    
    # Add target header to results file
    echo "----------------------------------------" >> "$RESULTS_FILE"
    echo "Target: $ip" >> "$RESULTS_FILE"
    echo "Scan Time: $(date)" >> "$RESULTS_FILE"
    echo "----------------------------------------" >> "$RESULTS_FILE"
    
    # Check if SNMP port is open with timeout
    print_info "  → Checking SNMP port 161/udp..."
    if timeout 10 nmap -sU -p 161 -Pn --open "$ip" 2>/dev/null | grep -q "161/udp open"; then
        print_success "SNMP port 161/udp is open on $ip"
        print_status "  → Running snmpwalk on $ip..."
        
        # Run snmpwalk with timeout and capture output
        if timeout 30 snmpwalk -v2c -c "$COMMUNITY" "$ip" "$OID" 2>/dev/null >> "$RESULTS_FILE"; then
            print_success "SNMP walk completed successfully for $ip"
            successful_scans=$((successful_scans + 1))
            echo "Status: SUCCESS - Data retrieved" >> "$RESULTS_FILE"
        else
            print_warning "SNMP walk failed for $ip (timeout or access denied)"
            failed_scans=$((failed_scans + 1))
            echo "Status: FAILED - No data retrieved (timeout/access denied)" >> "$RESULTS_FILE"
        fi
    else
        print_error "SNMP port 161/udp is closed or filtered on $ip"
        unreachable_targets=$((unreachable_targets + 1))
        echo "Status: UNREACHABLE - Port 161/udp closed or filtered" >> "$RESULTS_FILE"
    fi
    
    echo "" >> "$RESULTS_FILE"
    echo ""
    
done < "$INPUT_FILE"

# Add summary to results file
cat >> "$RESULTS_FILE" << EOF
================================================
SCAN SUMMARY
================================================
Total Targets Scanned: $total_targets
Successful SNMP Walks: $successful_scans
Failed SNMP Walks: $failed_scans
Unreachable Targets: $unreachable_targets
Scan Completed: $(date)
================================================
EOF

# Print final summary
echo ""
echo -e "${PURPLE}================================================${NC}"
print_success "SNMP scan completed!"
echo -e "${WHITE}Summary:${NC}"
echo -e "  ${GREEN}✓${NC} Total targets scanned: $total_targets"
echo -e "  ${GREEN}✓${NC} Successful SNMP walks: $successful_scans"
echo -e "  ${YELLOW}!${NC} Failed SNMP walks: $failed_scans"
echo -e "  ${RED}✗${NC} Unreachable targets: $unreachable_targets"
echo ""
print_info "All results saved to: $RESULTS_FILE"
echo -e "${PURPLE}================================================${NC}"

# Show success rate
if [[ $total_targets -gt 0 ]]; then
    success_rate=$(( (successful_scans * 100) / total_targets ))
    if [[ $success_rate -ge 75 ]]; then
        echo -e "${GREEN}Success Rate: $success_rate%${NC}"
    elif [[ $success_rate -ge 50 ]]; then
        echo -e "${YELLOW}Success Rate: $success_rate%${NC}"
    else
        echo -e "${RED}Success Rate: $success_rate%${NC}"
    fi
fi
