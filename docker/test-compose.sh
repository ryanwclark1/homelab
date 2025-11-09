#!/bin/bash
#
# Docker Compose Validation and Testing Script
# This script validates compose files and checks for common issues
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Test 1: Check if required files exist
test_file_existence() {
    print_header "Test 1: Checking File Existence"

    local files=(
        "docker-compose-arr.yml"
        "docker-compose-monitoring.yml"
        "docker-compose-network.yml"
        ".env.sample"
    )

    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            print_success "Found: $file"
        else
            print_error "Missing: $file"
        fi
    done
}

# Test 2: Validate YAML syntax
test_yaml_syntax() {
    print_header "Test 2: Validating YAML Syntax"

    local compose_files=(
        "docker-compose-arr.yml"
        "docker-compose-monitoring.yml"
        "docker-compose-network.yml"
    )

    for file in "${compose_files[@]}"; do
        if command -v yamllint &> /dev/null; then
            if yamllint -d relaxed "$file" &> /dev/null; then
                print_success "YAML syntax valid: $file"
            else
                print_error "YAML syntax errors in: $file"
                yamllint -d relaxed "$file" 2>&1 | head -5
            fi
        else
            print_warning "yamllint not installed, skipping YAML validation"
            print_info "Install with: pip install yamllint"
            break
        fi
    done
}

# Test 3: Validate Docker Compose configuration
test_compose_config() {
    print_header "Test 3: Validating Docker Compose Configuration"

    if ! command -v docker &> /dev/null; then
        print_warning "Docker not available, skipping compose validation"
        return
    fi

    local compose_files=(
        "docker-compose-arr.yml"
        "docker-compose-monitoring.yml"
        "docker-compose-network.yml"
    )

    for file in "${compose_files[@]}"; do
        print_info "Validating: $file"
        if docker compose -f "$file" config --quiet 2>&1; then
            print_success "Compose config valid: $file"
        else
            print_error "Compose config errors in: $file"
            docker compose -f "$file" config 2>&1 | grep -i error | head -5
        fi
    done
}

# Test 4: Check for duplicate service names
test_duplicate_services() {
    print_header "Test 4: Checking for Duplicate Service Names"

    local service_files=(arr/*.yml monitoring/*.yml network/*.yml)
    local all_services=()
    local duplicates=()

    for file in ${service_files[@]}; do
        [[ -f "$file" ]] || continue

        # Extract service names from each file
        local services=$(grep -E "^  [a-z0-9_-]+:" "$file" 2>/dev/null | sed 's/:.*//' | sed 's/^  //' | grep -v "^#" || true)

        for service in $services; do
            if [[ " ${all_services[@]} " =~ " ${service} " ]]; then
                if [[ ! " ${duplicates[@]} " =~ " ${service} " ]]; then
                    duplicates+=("$service")
                fi
            else
                all_services+=("$service")
            fi
        done
    done

    if [[ ${#duplicates[@]} -eq 0 ]]; then
        print_success "No duplicate service names found"
    else
        print_error "Duplicate service names found: ${duplicates[*]}"
    fi
}

# Test 5: Check for missing environment variables
test_env_variables() {
    print_header "Test 5: Checking Environment Variables"

    if [[ ! -f ".env.sample" ]]; then
        print_error ".env.sample not found"
        return
    fi

    # Extract all ${VAR} references from compose files
    local compose_files=(docker-compose-*.yml arr/*.yml monitoring/*.yml network/*.yml)
    local env_vars_used=()

    for file in "${compose_files[@]}"; do
        [[ -f "$file" ]] || continue

        local vars=$(grep -oE '\$\{[A-Z_]+[:-]?' "$file" 2>/dev/null | sed 's/\${//g' | sed 's/[:-].*//g' | sort -u || true)
        for var in $vars; do
            if [[ ! " ${env_vars_used[@]} " =~ " ${var} " ]]; then
                env_vars_used+=("$var")
            fi
        done
    done

    # Check if variables are in .env.sample
    local missing_vars=()
    for var in "${env_vars_used[@]}"; do
        if ! grep -q "^${var}=" ".env.sample" 2>/dev/null; then
            missing_vars+=("$var")
        fi
    done

    if [[ ${#missing_vars[@]} -eq 0 ]]; then
        print_success "All environment variables documented in .env.sample"
    else
        print_warning "Variables used but not in .env.sample: ${missing_vars[*]}"
    fi
}

# Test 6: Check for common issues
test_common_issues() {
    print_header "Test 6: Checking for Common Issues"

    # Check for hardcoded passwords
    print_info "Checking for hardcoded passwords..."
    local files_with_passwords=()
    for file in docker-compose-*.yml arr/*.yml monitoring/*.yml network/*.yml; do
        [[ -f "$file" ]] || continue

        if grep -i "password.*:" "$file" | grep -v "\${" | grep -v "^#" &> /dev/null; then
            files_with_passwords+=("$file")
        fi
    done

    if [[ ${#files_with_passwords[@]} -eq 0 ]]; then
        print_success "No hardcoded passwords found"
    else
        print_warning "Potential hardcoded passwords in: ${files_with_passwords[*]}"
    fi

    # Check for restart: "no"
    print_info "Checking for restart: 'no' policies..."
    local files_with_restart_no=$(grep -l 'restart: "no"' arr/*.yml monitoring/*.yml network/*.yml 2>/dev/null || true)

    if [[ -z "$files_with_restart_no" ]]; then
        print_success "All services use proper restart policies"
    else
        print_warning "Services with restart: 'no' found in: $files_with_restart_no"
    fi
}

# Test 7: Check network configuration
test_network_config() {
    print_header "Test 7: Checking Network Configuration"

    print_info "Checking for network conflicts..."

    # Extract network subnets
    local subnets=$(grep -h "subnet:" docker-compose-*.yml 2>/dev/null | sed 's/.*subnet: //' | sort)
    local unique_subnets=$(echo "$subnets" | sort -u)

    if [[ "$subnets" == "$unique_subnets" ]]; then
        print_success "No network subnet conflicts"
    else
        print_error "Duplicate network subnets found"
        echo "$subnets"
    fi
}

# Test 8: Verify x-common templates are used
test_templates_usage() {
    print_header "Test 8: Verifying Template Usage"

    # Check if arr services use common templates
    local arr_services=(arr/radarr.yml arr/sonarr.yml arr/lidarr.yml arr/whisparr.yml arr/prowlarr.yml)
    local services_using_templates=0

    for service in "${arr_services[@]}"; do
        if [[ -f "$service" ]] && grep -q "<<: \*common-arr" "$service"; then
            ((services_using_templates++))
        fi
    done

    if [[ $services_using_templates -eq ${#arr_services[@]} ]]; then
        print_success "All arr services use common templates"
    else
        print_warning "Only $services_using_templates/${#arr_services[@]} arr services use templates"
    fi

    # Check if exporters use common templates
    local exporters=(arr/*-exporter.yml)
    local exporters_using_templates=0
    local total_exporters=0

    for exporter in "${exporters[@]}"; do
        if [[ -f "$exporter" ]]; then
            ((total_exporters++))
            if grep -q "<<: \*common-exporter" "$exporter"; then
                ((exporters_using_templates++))
            fi
        fi
    done

    if [[ $exporters_using_templates -eq $total_exporters ]]; then
        print_success "All exporters use common templates"
    else
        print_warning "Only $exporters_using_templates/$total_exporters exporters use templates"
    fi
}

# Test 9: Check volume configurations
test_volumes() {
    print_header "Test 9: Checking Volume Configurations"

    print_info "Checking for volume mount consistency..."

    # Check if services use volume anchors
    local files_with_volumes=$(grep -l "volumes:" arr/*.yml monitoring/*.yml 2>/dev/null || true)
    local files_with_anchors=$(grep -l "\*common-volumes\|\*storage-volume" arr/*.yml 2>/dev/null || true)

    print_info "Services with volumes: $(echo "$files_with_volumes" | wc -w)"
    print_info "Services using volume anchors: $(echo "$files_with_anchors" | wc -w)"

    if [[ -n "$files_with_anchors" ]]; then
        print_success "Volume anchors are being used"
    else
        print_warning "No services using volume anchors"
    fi
}

# Test 10: Security checks
test_security() {
    print_header "Test 10: Security Checks"

    # Check for no-new-privileges
    local services_without_security=()
    for file in arr/*.yml monitoring/*.yml network/*.yml; do
        [[ -f "$file" ]] || continue

        if grep -q "privileged: true" "$file" && ! grep -q "no-new-privileges" "$file"; then
            services_without_security+=("$file")
        fi
    done

    if [[ ${#services_without_security[@]} -eq 0 ]]; then
        print_success "Privileged containers have security opts"
    else
        print_warning "Privileged containers without security opts: ${services_without_security[*]}"
    fi

    # Check for services running as root
    print_info "Checking for PUID/PGID usage..."
    local services_with_user_config=$(grep -l "PUID\|PGID" arr/*.yml monitoring/*.yml 2>/dev/null | wc -l)

    if [[ $services_with_user_config -gt 0 ]]; then
        print_success "$services_with_user_config services configured with PUID/PGID"
    fi
}

# Main execution
main() {
    print_header "Docker Compose Configuration Test Suite"
    echo "Testing in: $SCRIPT_DIR"
    echo "Started: $(date)"

    test_file_existence
    test_yaml_syntax
    test_compose_config
    test_duplicate_services
    test_env_variables
    test_common_issues
    test_network_config
    test_templates_usage
    test_volumes
    test_security

    # Summary
    print_header "Test Summary"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}All tests passed! ✓${NC}\n"
        exit 0
    else
        echo -e "\n${RED}Some tests failed. Please review the output above.${NC}\n"
        exit 1
    fi
}

# Run tests
main "$@"
