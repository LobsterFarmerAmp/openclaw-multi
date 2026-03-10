#!/bin/bash
#
# OpenClaw 瀹炰緥鐢熸垚鑴氭湰 v2
# 鏍规嵁 configs/ 鐩綍涓嬬殑 YAML 閰嶇疆鏂囦欢鍔ㄦ€佺敓鎴愬疄渚?#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="$BASE_DIR/configs"
INSTANCES_DIR="$BASE_DIR/instances"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() { echo -e "${CYAN}$1${NC}"; }

show_help() {
    cat << EOF
OpenClaw 瀹炰緥鐢熸垚鑴氭湰 v2

鐢ㄦ硶锛?0 [閫夐」]

閫夐」:
  --config <鏂囦欢>  鎸囧畾鍗曚釜閰嶇疆鏂囦欢鐢熸垚
  --all            鐢熸垚鎵€鏈夐厤缃?(榛樿)
  --force          寮哄埗閲嶆柊鐢熸垚 (瑕嗙洊閰嶇疆锛屼繚鐣欐暟鎹?
  --dry-run        棰勮鎿嶄綔锛屼笉瀹為檯鐢熸垚
  --compose        鐢熸垚 docker-compose.yml
  --help           鏄剧ず甯姪

绀轰緥:
  $0                           # 鐢熸垚鎵€鏈夊疄渚?  $0 --config custom.yaml      # 鐢熸垚鎸囧畾閰嶇疆
  $0 --all --force --compose   # 寮哄埗閲嶆柊鐢熸垚骞舵洿鏂?compose

EOF
}

check_dependencies() {
    if ! command -v yq &> /dev/null; then
        print_error "缂哄皯渚濊禆锛歽q (YAML 瑙ｆ瀽鍣?"
        print_info "瀹夎锛歨ttps://github.com/mikefarah/yq#install"
        exit 1
    fi
}

get_default_personality() {
    local role="$1"
    case "$role" in
        绠″ | 澶х瀹? echo "楂樻晥骞茬粌锛岀畝娲佺洿鎺ワ紝鍔炰簨鍒╄惤锛屾敞閲嶆晥鐜? ;;
        鍔╂墜 | 灏忓姪鎵? echo "鍙嬪ソ鐑儏锛岃€愬績缁嗚嚧锛屼箰浜庡姪浜猴紝鍠勪簬鍊惧惉" ;;
        涓撳 | 鎶€鏈笓瀹? echo "涓ヨ皑涓撲笟锛屾繁鍏ユ祬鍑猴紝娉ㄩ噸缁嗚妭锛岃拷姹傜簿纭? ;;
        鍒涙剰 | 璁捐甯? echo "瀵屾湁鍒涙剰锛屾€濈淮娲昏穬锛屽缇庣嫭鐗癸紝鍠勪簬琛ㄨ揪" ;;
        *) echo "鑱槑鏈烘櫤锛岄€傚簲鍔涘己锛屽杽浜庡涔? ;;
    esac
}

get_default_voice() {
    local role="$1"
    case "$role" in
        绠″ | 澶х瀹? echo "涓撲笟銆佺洿鎺ャ€佷笉搴熻瘽锛岃鍔ㄥ鍚? ;;
        鍔╂墜 | 灏忓姪鎵? echo "娓╁拰銆佽€愬績銆侀紦鍔辨€э紝鏄撲簬浜茶繎" ;;
        涓撳 | 鎶€鏈笓瀹? echo "涓ヨ皑銆佸噯纭€佹潯鐞嗘竻鏅帮紝涓撲笟鏈閫傚害" ;;
        鍒涙剰 | 璁捐甯? echo "鐢熷姩銆佸舰璞°€佸瘜鏈夋劅鏌撳姏锛屽杽鐢ㄦ瘮鍠? ;;
        *) echo "鑷劧銆佺湡璇氥€佹湁鏉＄悊" ;;
    esac
}

generate_channels_config() {
    local config_file="$1"
    local channels=$(yq eval '.channels[]' "$config_file" 2>/dev/null || echo "")
    local config=""
    
    if [[ -z "$channels" ]]; then
        echo ""
        return
    fi
    
    while IFS= read -r channel; do
        case "$channel" in
            feishu)
                config+="\n    \"feishu\": { \"enabled\": true, \"appId\": \"\${FEISHU_APP_ID}\", \"appSecret\": \"\${FEISHU_APP_SECRET}\" },"
                ;;
            telegram)
                config+="\n    \"telegram\": { \"enabled\": true, \"botToken\": \"\${TELEGRAM_BOT_TOKEN}\" },"
                ;;
            discord)
                config+="\n    \"discord\": { \"enabled\": true, \"token\": \"\${DISCORD_BOT_TOKEN}\" },"
                ;;
        esac
    done <<< "$channels"
    
    config="${config%,}"
    echo -e "$config"
}

create_directories() {
    local instance_dir="$1"
    mkdir -p "$instance_dir"/{config,workspace,data/{sessions,credentials,logs},memory}
    mkdir -p "$instance_dir/workspace/skills"
}

generate_identity() {
    local dir="$1" name="$2" role="$3" emoji="$4" personality="$5"
    cat > "$dir/workspace/IDENTITY.md" << EOF
# IDENTITY.md - Who Am I?

- **Name:** ${name}
- **Creature:** AI ${role} / 鏅鸿兘${role}
- **Vibe:** ${personality}
- **Emoji:** ${emoji}
- **Avatar:**

---
This isn't just metadata. It's the start of figuring out who you are.
EOF
}

generate_soul() {
    local dir="$1" name="$2" role="$3" emoji="$4" personality="$5" voice="$6"
    cat > "$dir/workspace/SOUL.md" << EOF
# SOUL.md - Who You Are

## Your Role: ${role}
${personality}

### Communication Style
${voice}

## Vibe
${emoji} ${name} 鈥?${role}妯″紡宸叉縺娲?EOF
}

generate_user() {
    local dir="$1" personality="$2"
    cat > "$dir/workspace/USER.md" << EOF
# USER.md - About Your Human

- **Name:** 鑰佺埛
- **What to call them:** 鑰佺埛
- **Timezone:** Asia/Shanghai
- **Notes:** ${personality}
EOF
}

generate_agents() {
    local dir="$1"
    cp "$BASE_DIR/../AGENTS.md" "$dir/workspace/AGENTS.md" 2>/dev/null || cat > "$dir/workspace/AGENTS.md" << 'EOF'
# AGENTS.md - Your Workspace
Read SOUL.md, USER.md, memory/*.md on startup.
EOF
}

generate_tools() {
    local dir="$1"
    cp "$BASE_DIR/../TOOLS.md" "$dir/workspace/TOOLS.md" 2>/dev/null || cat > "$dir/workspace/TOOLS.md" << 'EOF'
# TOOLS.md - Local Notes
Environment-specific settings go here.
EOF
}

generate_openclaw_config() {
    local dir="$1" config_file="$2"
    local name=$(yq eval '.name' "$config_file")
    local emoji=$(yq eval '.emoji // "馃"' "$config_file")
    local model=$(yq eval '.model // "moonshot/kimi-k2.5"' "$config_file")
    local channels=$(generate_channels_config "$config_file")
    
    cat > "$dir/config/openclaw.json" << EOF
{
  "agent": { "model": "${model}", "name": "${name}", "emoji": "${emoji}" },
  "gateway": { "bind": "lan", "port": 18789, "mode": "local" },
  "channels": {${channels}
  },
  "models": {
    "profiles": [{ "name": "primary", "provider": "moonshot", "model": "kimi-k2.5", "apiKey": "\${MOONSHOT_API_KEY}" }]
  },
  "logging": { "level": "info", "file": "/home/node/.openclaw/data/logs/openclaw.log" }
}
EOF
}

generate_env() {
    local dir="$1" id="$2" name="$3" role="$4" port="$5"
    cat > "$dir/.env" << EOF
INSTANCE_ID=${id}
INSTANCE_NAME=${name}
INSTANCE_ROLE=${role}
INSTANCE_PORT=${port}
OPENCLAW_IMAGE=ghcr.io/openclaw/openclaw:latest
NODE_ENV=production
EOF
}

generate_memory() {
    local dir="$1" name="$2" role="$3"
    cat > "$dir/workspace/MEMORY.md" << EOF
# MEMORY.md

- **Name:** ${name}
- **Role:** ${role}
- **Created:** $(date '+%Y-%m-%d')
EOF
}

generate_heartbeat() {
    local dir="$1"
    cat > "$dir/workspace/HEARTBEAT.md" << 'EOF'
# HEARTBEAT.md
# Add periodic tasks below
EOF
}

generate_instance_info() {
    local dir="$1" config_file="$2"
    yq eval '.' "$config_file" > "$dir/instance-info.json"
}

generate_instance() {
    local config_file="$1"
    local config_name=$(basename "$config_file")
    
    print_header "澶勭悊锛?config_name"
    
    local id=$(yq eval '.id' "$config_file")
    local name=$(yq eval '.name' "$config_file")
    local role=$(yq eval '.role // "鍔╂墜"' "$config_file")
    local emoji=$(yq eval '.emoji // "馃"' "$config_file")
    local port=$(yq eval '.port' "$config_file")
    local model=$(yq eval '.model // "moonshot/kimi-k2.5"' "$config_file")
    local personality=$(yq eval '.personality // ""' "$config_file")
    local voice=$(yq eval '.voice // ""' "$config_file")
    
    [[ -z "$personality" || "$personality" == "null" ]] && personality=$(get_default_personality "$role")
    [[ -z "$voice" || "$voice" == "null" ]] && voice=$(get_default_voice "$role")
    
    local instance_dir="$INSTANCES_DIR/$id"
    
    if [[ -d "$instance_dir" && "$FORCE" != "true" ]]; then
        print_warning "瀹炰緥 $id 宸插瓨鍦紝浣跨敤 --force 閲嶆柊鐢熸垚"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "[DRY-RUN] $id: $name $emoji (绔彛:$port)"
        return 0
    fi
    
    create_directories "$instance_dir"
    generate_identity "$instance_dir" "$name" "$role" "$emoji" "$personality"
    generate_soul "$instance_dir" "$name" "$role" "$emoji" "$personality" "$voice"
    generate_user "$instance_dir" "$personality"
    generate_agents "$instance_dir"
    generate_tools "$instance_dir"
    generate_openclaw_config "$instance_dir" "$config_file"
    generate_env "$instance_dir" "$id" "$name" "$role" "$port"
    generate_memory "$instance_dir" "$name" "$role"
    generate_heartbeat "$instance_dir"
    generate_instance_info "$instance_dir" "$config_file"
    
    print_success "瀹炰緥 $id 鐢熸垚瀹屾垚"
}

generate_compose() {
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "[DRY-RUN] 灏嗙敓鎴?docker-compose.yml"
        return 0
    fi
    
    print_info "鐢熸垚 docker-compose.yml..."
    local compose="$BASE_DIR/docker-compose.multi.yml"
    
    cat > "$compose" << 'EOF'
version: '3.8'
# 鐢?generate-instances.sh 鑷姩鐢熸垚 - 涓嶈鎵嬪姩缂栬緫

services:
EOF
    
    for config_file in "$CONFIGS_DIR"/*.yaml "$CONFIGS_DIR"/*.yml; do
        [[ -f "$config_file" ]] || continue
        
        local id=$(yq eval '.id' "$config_file")
        local port=$(yq eval '.port' "$config_file")
        local autostart=$(yq eval '.autostart // true' "$config_file")
        
        local profile_line=""
        if [[ "$autostart" == "false" ]]; then
            profile_line="    profiles: [\"$id\"]"
        fi
        
        cat >> "$compose" << EOF

  openclaw-${id}:
    container_name: openclaw-${id}
    image: \${OPENCLAW_IMAGE:-ghcr.io/openclaw/openclaw:latest}
    ports:
      - "${port}:18789"
    volumes:
      - ./instances/${id}/config:/home/node/.openclaw
      - ./instances/${id}/workspace:/home/node/.openclaw/workspace
      - ./instances/${id}/data:/home/node/.openclaw/data
    environment:
      - OPENCLAW_INSTANCE_ID=${id}
      - NODE_ENV=production
      - MOONSHOT_API_KEY=\${${id^^}_MOONSHOT_API_KEY:-}
      - FEISHU_APP_ID=\${${id^^}_FEISHU_APP_ID:-}
      - FEISHU_APP_SECRET=\${${id^^}_FEISHU_APP_SECRET:-}
      - TELEGRAM_BOT_TOKEN=\${${id^^}_TELEGRAM_BOT_TOKEN:-}
      - DISCORD_BOT_TOKEN=\${${id^^}_DISCORD_BOT_TOKEN:-}
    networks:
      - openclaw-${id}-net
    restart: unless-stopped
${profile_line}

  openclaw-cli-${id}:
    container_name: openclaw-cli-${id}
    image: \${OPENCLAW_IMAGE:-ghcr.io/openclaw/openclaw:latest}
    network_mode: "service:openclaw-${id}"
    volumes:
      - ./instances/${id}/config:/home/node/.openclaw
      - ./instances/${id}/workspace:/home/node/.openclaw/workspace
      - ./instances/${id}/data:/home/node/.openclaw/data
    environment:
      - OPENCLAW_INSTANCE_ID=${id}
      - NODE_ENV=production
    profiles:
      - cli-${id}
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - NET_RAW
      - NET_ADMIN

networks:
  openclaw-${id}-net:
    driver: bridge

EOF
    done
    
    print_success "docker-compose.yml 鐢熸垚瀹屾垚"
}

# 涓荤▼搴?FORCE=false
DRY_RUN=false
GENERATE_COMPOSE=false
CONFIG_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --config) CONFIG_FILE="$2"; shift 2 ;;
        --all) shift ;;
        --force) FORCE=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --compose) GENERATE_COMPOSE=true; shift ;;
        --help) show_help; exit 0 ;;
        *) print_error "鏈煡閫夐」锛?1"; show_help; exit 1 ;;
    esac
done

check_dependencies

print_info "OpenClaw 瀹炰緥鐢熸垚鑴氭湰 v2"
print_info "========================"

if [[ -n "$CONFIG_FILE" ]]; then
    generate_instance "$CONFIG_FILE"
else
    for config in "$CONFIGS_DIR"/*.yaml "$CONFIGS_DIR"/*.yml; do
        [[ -f "$config" ]] && generate_instance "$config"
    done
fi

if [[ "$GENERATE_COMPOSE" == "true" ]] || [[ -z "$CONFIG_FILE" ]]; then
    generate_compose
fi

print_success "瀹屾垚!"

