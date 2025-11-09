#!/bin/bash
#
# Docker Compose Stack Management Script
# Simplifies managing multiple Docker Compose stacks in the homelab
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Stack definitions
declare -A STACKS=(
    ["arr"]="docker-compose-arr.yml"
    ["monitoring"]="docker-compose-monitoring.yml"
    ["network"]="docker-compose-network.yml"
    ["n8n"]="n8n/docker-compose.yml"
    ["semaphore"]="semaphore/docker-compose.yml"
    ["atuin"]="atuin/docker-compose.yml"
    ["immich"]="immich/docker-compose.yml"
    ["influxdb"]="influxdb/docker-compose.yml"
)

# Helper functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# Usage information
usage() {
    cat << EOF
Docker Compose Stack Management Script

Usage: $0 [COMMAND] [STACK] [OPTIONS]

Commands:
    list                List all available stacks
    status [STACK]      Show status of stack(s)
    start [STACK]       Start stack(s)
    stop [STACK]        Stop stack(s)
    restart [STACK]     Restart stack(s)
    logs [STACK]        View logs for stack(s)
    pull [STACK]        Pull latest images for stack(s)
    update [STACK]      Pull images and restart stack(s)
    config [STACK]      Validate stack configuration
    ps [STACK]          List running containers in stack(s)
    down [STACK]        Stop and remove containers for stack(s)
    help                Show this help message

Stacks:
    arr                 Media management stack (Radarr, Sonarr, etc.)
    monitoring          Monitoring stack (Prometheus, Grafana, etc.)
    network             Network services (Traefik)
    n8n                 N8N workflow automation
    semaphore           Semaphore Ansible UI
    atuin               Atuin shell history
    immich              Immich photo management
    influxdb            InfluxDB time-series database
    all                 All stacks

Options:
    -f, --follow        Follow logs (for logs command)
    -t, --tail N        Tail last N lines of logs
    -q, --quiet         Quiet mode
    -h, --help          Show this help message

Examples:
    $0 list
    $0 status arr
    $0 start arr
    $0 restart monitoring
    $0 logs arr --follow
    $0 update all
    $0 pull arr monitoring

EOF
    exit 0
}

# List all stacks
list_stacks() {
    print_header "Available Docker Compose Stacks"

    for stack in "${!STACKS[@]}"; do
        file="${STACKS[$stack]}"
        if [[ -f "$file" ]]; then
            status=$(docker compose -f "$file" ps --quiet 2>/dev/null | wc -l || echo "0")
            if [[ "$status" -gt 0 ]]; then
                echo -e "${GREEN}●${NC} $stack - ${CYAN}$file${NC} (${GREEN}$status containers running${NC})"
            else
                echo -e "${YELLOW}○${NC} $stack - ${CYAN}$file${NC} (${YELLOW}stopped${NC})"
            fi
        else
            echo -e "${RED}✗${NC} $stack - ${CYAN}$file${NC} (${RED}file not found${NC})"
        fi
    done
}

# Get stack file
get_stack_file() {
    local stack=$1
    if [[ "$stack" == "all" ]]; then
        echo "all"
        return
    fi

    if [[ -z "${STACKS[$stack]}" ]]; then
        print_error "Unknown stack: $stack"
        echo "Run '$0 list' to see available stacks"
        exit 1
    fi

    echo "${STACKS[$stack]}"
}

# Execute command on stack(s)
execute_on_stacks() {
    local command=$1
    shift
    local stacks=("$@")

    if [[ "${stacks[0]}" == "all" ]]; then
        stacks=("${!STACKS[@]}")
    fi

    for stack in "${stacks[@]}"; do
        local file=$(get_stack_file "$stack")
        if [[ "$file" == "all" ]]; then
            continue
        fi

        if [[ ! -f "$file" ]]; then
            print_error "Stack file not found: $file"
            continue
        fi

        print_info "Executing '$command' on stack: $stack"

        case "$command" in
            status)
                docker compose -f "$file" ps
                ;;
            start)
                docker compose -f "$file" up -d
                print_success "Started $stack"
                ;;
            stop)
                docker compose -f "$file" stop
                print_success "Stopped $stack"
                ;;
            restart)
                docker compose -f "$file" restart
                print_success "Restarted $stack"
                ;;
            logs)
                docker compose -f "$file" logs "${LOG_OPTS[@]}"
                ;;
            pull)
                docker compose -f "$file" pull
                print_success "Pulled images for $stack"
                ;;
            update)
                docker compose -f "$file" pull
                docker compose -f "$file" up -d
                print_success "Updated $stack"
                ;;
            config)
                if docker compose -f "$file" config --quiet; then
                    print_success "Configuration valid for $stack"
                else
                    print_error "Configuration invalid for $stack"
                fi
                ;;
            ps)
                docker compose -f "$file" ps
                ;;
            down)
                print_warning "Stopping and removing containers for $stack"
                docker compose -f "$file" down
                print_success "Removed $stack"
                ;;
            *)
                print_error "Unknown command: $command"
                exit 1
                ;;
        esac
        echo ""
    done
}

# Main
main() {
    if [[ $# -eq 0 ]]; then
        usage
    fi

    local command=$1
    shift

    case "$command" in
        list|ls)
            list_stacks
            ;;
        help|--help|-h)
            usage
            ;;
        status|start|stop|restart|pull|update|config|ps|down)
            if [[ $# -eq 0 ]]; then
                print_error "No stack specified"
                echo "Usage: $0 $command [STACK]"
                exit 1
            fi
            execute_on_stacks "$command" "$@"
            ;;
        logs)
            if [[ $# -eq 0 ]]; then
                print_error "No stack specified"
                echo "Usage: $0 logs [STACK] [OPTIONS]"
                exit 1
            fi

            LOG_OPTS=()
            local stacks=()

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -f|--follow)
                        LOG_OPTS+=("--follow")
                        shift
                        ;;
                    -t|--tail)
                        LOG_OPTS+=("--tail" "$2")
                        shift 2
                        ;;
                    *)
                        stacks+=("$1")
                        shift
                        ;;
                esac
            done

            if [[ ${#stacks[@]} -eq 0 ]]; then
                print_error "No stack specified"
                exit 1
            fi

            execute_on_stacks "logs" "${stacks[@]}"
            ;;
        *)
            print_error "Unknown command: $command"
            usage
            ;;
    esac
}

main "$@"
