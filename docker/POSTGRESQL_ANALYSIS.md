# PostgreSQL Instance Analysis

## Overview
This document analyzes the PostgreSQL instances across the homelab and evaluates consolidation options.

## Current PostgreSQL Instances

### 1. Atuin (Shell History Service)
**Location:** `atuin/docker-compose.yml`
**Image:** `postgres:16`
**Container Name:** `postgres`
**Database:** `atuin`
**Features:**
- Standard PostgreSQL 16
- Automated daily backups via `prodrigestivill/postgres-backup-local`
- Healthcheck enabled
- Linked to Atuin and Tailscale services

**Volume:** Named volume `pgdata`
**Credentials:** Configured via `.env` (ATUIN_DB_USERNAME, ATUIN_DB_PASSWORD)

---

### 2. N8N (Workflow Automation)
**Location:** `n8n/docker-compose.yml`
**Image:** `postgres:16-alpine`
**Container Name:** `postgres`
**Database:** `n8n`
**Features:**
- Alpine-based PostgreSQL 16 (smaller footprint)
- **SECURITY ISSUE:** Hardcoded credentials (`n8n`/`n8n`)
- Standard configuration

**Volume:** Bind mount `./data/postgres`
**Port Exposed:** 5432

---

### 3. Semaphore (Ansible UI)
**Location:** `semaphore/docker-compose.yml`
**Image:** `postgres:16-alpine`
**Container Name:** `postgres`
**Database:** `semaphore`
**Features:**
- Alpine-based PostgreSQL 16
- **CONFIGURATION ISSUE:** DB_PASS vs DB_PASSWORD mismatch in environment variables
- Standard configuration

**Volume:** Named volume `semaphore-postgres`
**Credentials:** Configured via `.env` (defaults: semaphore/semaphore)

---

### 4. Immich (Photo Management)
**Location:** `immich/docker-compose.yml`
**Image:** `tensorchord/pgvecto-rs:pg16-v0.2.1`
**Container Name:** `immich_postgres`
**Database:** Configured via `.env`
**Features:**
- **SPECIALIZED:** PostgreSQL 16 with pgvecto-rs extension for vector similarity search
- Custom PostgreSQL configuration with shared_preload_libraries=vectors.so
- Advanced healthchecks including checksum validation
- Optimized for AI/ML workloads
- Custom configuration: shared_buffers=512MB, max_wal_size=2GB
- Logging and compression enabled

**Volume:** Configured via `.env` (IMMICH_DB_DATA_LOCATION)
**Port Exposed:** 5432
**Credentials:** Configured via `.env`

**⚠️ CANNOT BE CONSOLIDATED:** Requires specialized pgvecto-rs extension for vector operations

---

## Consolidation Analysis

### Why Consolidation is Complex

#### 1. **Standalone Application Deployment**
Each PostgreSQL instance is configured for a standalone application in its own directory:
```
docker/
├── atuin/docker-compose.yml
├── n8n/docker-compose.yml
├── semaphore/docker-compose.yml
└── immich/docker-compose.yml
```

**Implication:** Consolidating would require:
- Creating a shared PostgreSQL service
- Modifying each app's compose file to reference external database
- Managing cross-directory dependencies
- Coordinating startup order

#### 2. **Container Name Conflicts**
Three instances use the same container name `postgres`:
- Atuin: `postgres`
- N8N: `postgres`
- Semaphore: `postgres`

**Current State:** No conflicts because they're in separate compose projects
**After Consolidation:** Would need unique names or network aliases

#### 3. **Immich's Specialized Requirements**
Immich requires pgvecto-rs extension which:
- Is not available in standard PostgreSQL images
- Cannot be easily added to standard PostgreSQL
- Requires specific configuration and preloaded libraries
- Used for AI/ML vector similarity search

**Verdict:** Immich must remain separate

---

## Consolidation Options

### Option 1: Full Separation (Current - RECOMMENDED)
**Keep all instances separate**

**Pros:**
- ✅ Simple deployment model
- ✅ No cross-dependencies
- ✅ Each app can be deployed/removed independently
- ✅ Isolated failures (one DB issue doesn't affect all apps)
- ✅ Easy to backup per-application
- ✅ Matches the standalone app architecture

**Cons:**
- ❌ Multiple PostgreSQL instances consuming resources
- ❌ Slight duplication in configuration

**Resource Impact:**
- Atuin: ~50-100MB RAM
- N8N: ~30-50MB RAM (Alpine)
- Semaphore: ~30-50MB RAM (Alpine)
- Immich: ~512MB RAM (configured)
- **Total:** ~650-750MB RAM

---

### Option 2: Partial Consolidation (3-in-1)
**Consolidate Atuin, N8N, Semaphore; Keep Immich separate**

**Implementation:**
1. Create `docker/shared/postgres/docker-compose.yml`
2. Single postgres:16 instance with 3 databases
3. Each app connects via network alias
4. Shared backup strategy

**Pros:**
- ✅ Reduced resource usage (~100-150MB total for 3 apps)
- ✅ Centralized database management
- ✅ Single backup process
- ✅ Easier monitoring

**Cons:**
- ❌ Breaks standalone deployment model
- ❌ Adds cross-directory complexity
- ❌ Requires network configuration
- ❌ Single point of failure for 3 apps
- ❌ Harder to remove individual apps
- ❌ Needs migration process
- ❌ More complex startup dependencies

**Configuration Example:**
```yaml
services:
  shared-postgres:
    image: postgres:16
    container_name: shared-postgres
    environment:
      POSTGRES_MULTIPLE_DATABASES: atuin,n8n,semaphore
    networks:
      - atuin_net
      - n8n_net
      - semaphore_net
```

---

### Option 3: Docker Swarm / External Database
**Use external PostgreSQL (Docker Swarm service or external server)**

**Not Recommended:**
- Adds significant complexity
- Requires Docker Swarm mode or external infrastructure
- Overkill for homelab use case

---

## Recommendations

### Recommendation: Keep Current Setup ✅

**Rationale:**
1. **Architectural Consistency:** The homelab uses a "standalone apps in separate directories" pattern. Consolidating PostgreSQL breaks this pattern.

2. **Resource Trade-off:** The ~400MB RAM saved doesn't justify the added complexity for a homelab.

3. **Operational Simplicity:** Independent databases mean:
   - Easy to spin up/down individual services
   - No cascade failures
   - Simple backups (Atuin already has automated backups)
   - Clear ownership and separation

4. **Immich Must Be Separate Anyway:** Since Immich requires specialized PostgreSQL, we'd still have 2 instances minimum.

### Immediate Improvements (Without Consolidation)

#### 1. Fix N8N Hardcoded Credentials ⚠️
**File:** `n8n/docker-compose.yml`

**Current:**
```yaml
environment:
  - DB_POSTGRESDB_USER=n8n
  - DB_POSTGRESDB_PASSWORD=n8n
  - N8N_BASIC_AUTH_USER=username
  - N8N_BASIC_AUTH_PASSWORD=password
```

**Recommended:**
```yaml
env_file:
  - .env
environment:
  - DB_POSTGRESDB_USER=${N8N_DB_USER:-n8n}
  - DB_POSTGRESDB_PASSWORD=${N8N_DB_PASSWORD}
  - N8N_BASIC_AUTH_USER=${N8N_AUTH_USER}
  - N8N_BASIC_AUTH_PASSWORD=${N8N_AUTH_PASSWORD}
```

#### 2. Fix Semaphore Environment Variable Mismatch ⚠️
**File:** `semaphore/docker-compose.yml`

**Issue:** Service uses `DB_PASS` but postgres expects `DB_PASSWORD`

**Fix:**
```yaml
# In semaphore service:
SEMAPHORE_DB_PASS: ${DB_PASSWORD:-semaphore}

# In postgres service:
POSTGRES_PASSWORD: ${DB_PASSWORD:-semaphore}
```

#### 3. Add Healthchecks
Add healthchecks to N8N and Semaphore PostgreSQL instances:

```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -d ${DB_NAME} -U ${DB_USER}"]
  start_period: 20s
  interval: 10s
```

#### 4. Add Backup Services
Consider adding automated backups (like Atuin has) to N8N and Semaphore:

```yaml
backup:
  image: prodrigestivill/postgres-backup-local:latest
  environment:
    POSTGRES_HOST: postgres
    POSTGRES_DB: ${DB_NAME}
    POSTGRES_USER: ${DB_USER}
    POSTGRES_PASSWORD: ${DB_PASSWORD}
    SCHEDULE: "@daily"
  volumes:
    - ./backups:/db_dumps
  depends_on:
    postgres:
      condition: service_healthy
```

#### 5. Standardize Volume Patterns
- Atuin: Uses named volumes (good for production)
- N8N: Uses bind mounts (good for development)
- Semaphore: Uses named volumes
- Immich: Uses .env-configured path

**Recommendation:** Document the pattern but keep as-is (each has valid use case)

---

## Summary

| Instance | Image | Can Consolidate? | Recommendation |
|----------|-------|-----------------|----------------|
| Atuin | postgres:16 | Technically yes | Keep separate |
| N8N | postgres:16-alpine | Technically yes | Keep separate, fix credentials |
| Semaphore | postgres:16-alpine | Technically yes | Keep separate, fix env vars |
| Immich | pgvecto-rs:pg16 | ❌ NO | Must stay separate |

**Overall:** Maintain current architecture, apply security and reliability improvements.

---

## Future Considerations

If resource usage becomes a concern:
1. Monitor actual PostgreSQL resource consumption
2. Consider upgrading host RAM (cheaper than complexity)
3. If consolidation is truly needed, start with just N8N + Semaphore (smallest impact)

**Last Updated:** 2025-11-08
