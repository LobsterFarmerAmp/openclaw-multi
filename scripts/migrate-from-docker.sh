#!/bin/bash
#
# 迁移脚本：从旧 Docker 架构迁移到 Multi-Session 架构
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

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

echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Docker 架构 → Multi-Session 架构迁移       ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
echo ""

# 检查旧架构是否存在
if [[ ! -d "$BASE_DIR/instances" ]]; then
    print_error "未找到旧架构数据 (instances/ 目录不存在)"
    exit 1
fi

print_info "发现旧架构数据，开始迁移..."

# 1. 迁移 configs/ → personas/
if [[ -d "$BASE_DIR/configs" ]]; then
    print_info "迁移 configs/ → personas/..."
    for config in "$BASE_DIR/configs"/*.yaml "$BASE_DIR/configs"/*.yml; do
        [[ -f "$config" ]] || continue
        local filename=$(basename "$config")
        if [[ ! -f "$BASE_DIR/personas/$filename" ]]; then
            cp "$config" "$BASE_DIR/personas/"
            print_success "  已复制: $filename"
        fi
    done
fi

# 2. 迁移 instances/ → sessions/
print_info "迁移 instances/ → sessions/..."
for instance in "$BASE_DIR/instances"/*; do
    [[ -d "$instance" ]] || continue
    
    local instance_name=$(basename "$instance")
    local session_dir="$BASE_DIR/sessions/$instance_name"
    
    if [[ -d "$session_dir" ]]; then
        print_warning "  Session $instance_name 已存在，跳过"
        continue
    fi
    
    # 迁移 workspace
    if [[ -d "$instance/workspace" ]]; then
        mkdir -p "$session_dir"
        cp -r "$instance/workspace/"* "$session_dir/" 2>/dev/null || true
        print_success "  已迁移: $instance_name"
    fi
done

# 3. 迁移 shared/
if [[ -d "$BASE_DIR/shared" ]]; then
    print_info "检查 shared/ 目录..."
    # skills 和 extensions 已经在 shared/ 中
fi

echo ""
print_success "迁移完成！"
echo ""
echo -e "${CYAN}下一步操作:${NC}"
echo "1. 检查 personas/ 目录下的角色配置"
echo "2. 运行: ./scripts/init-persona.sh --all"
echo "3. 停止旧容器: docker compose -f docker-compose.multi.yml down"
echo "4. 使用新架构启动 Gateway"
echo ""
echo -e "${YELLOW}注意: 旧数据仍保留在 instances/ 目录，确认无误后可手动删除${NC}"
