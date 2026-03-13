#!/bin/bash
#
# 列出所有可用的 Personas 和 Sessions
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
PERSONAS_DIR="$BASE_DIR/personas"
SESSIONS_DIR="$BASE_DIR/sessions"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       OpenClaw Multi-Session 角色列表          ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
echo ""

# 列出所有 personas
if [[ -d "$PERSONAS_DIR" ]]; then
    echo -e "${BLUE}📋 已定义角色 (personas/):${NC}"
    for config in "$PERSONAS_DIR"/*.yaml "$PERSONAS_DIR"/*.yml; do
        [[ -f "$config" ]] || continue
        local id=$(yq eval '.id' "$config" 2>/dev/null)
        local name=$(yq eval '.name' "$config" 2>/dev/null)
        local emoji=$(yq eval '.emoji // "🤖"' "$config" 2>/dev/null)
        local role=$(yq eval '.role // "助手"' "$config" 2>/dev/null)
        echo "   $emoji $name ($id) - $role"
    done
else
    echo -e "${YELLOW}⚠️  personas/ 目录不存在${NC}"
fi

echo ""

# 列出已初始化的 sessions
if [[ -d "$SESSIONS_DIR" ]]; then
    echo -e "${GREEN}✅ 已初始化 Session (sessions/):${NC}"
    for session in "$SESSIONS_DIR"/*; do
        [[ -d "$session" ]] || continue
        local session_name=$(basename "$session")
        if [[ -f "$session/IDENTITY.md" ]]; then
            local name=$(grep "^\- \*\*Name:\*\*" "$session/IDENTITY.md" | sed 's/.*:\*\* //')
            local emoji=$(grep "^\- \*\*Emoji:\*\*" "$session/IDENTITY.md" | sed 's/.*:\*\* //')
            echo "   $emoji $name ($session_name)"
        else
            echo "   🤖 $session_name"
        fi
    done
else
    echo -e "${YELLOW}⚠️  sessions/ 目录不存在${NC}"
fi

echo ""
echo -e "${CYAN}使用方式:${NC}"
echo "  ./scripts/init-persona.sh personas/<role>.yaml  # 初始化新角色"
echo "  openclaw chat --session <session-id>             # 切换到指定 Session"
