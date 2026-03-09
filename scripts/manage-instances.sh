#!/bin/bash
#
# OpenClaw 多实例管理脚本
# 用于管理多个 OpenClaw 实例的生命周期
#

set -e

# 默认配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
INSTANCES_DIR="$BASE_DIR/instances"
COMPOSE_FILE="$BASE_DIR/docker-compose.multi.yml"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 打印函数
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() { echo -e "${CYAN}$1${NC}"; }

# 显示帮助
show_help() {
    cat << EOF
OpenClaw 多实例管理脚本

用法: $0 <命令> [参数]

命令:
  status [实例ID]          查看实例状态
  start <实例ID>           启动指定实例
  stop <实例ID>            停止指定实例
  restart <实例ID>         重启指定实例
  logs <实例ID>            查看实例日志
  shell <实例ID>           进入实例容器
  config <实例ID>          编辑实例配置
  backup <实例ID>          备份实例数据
  restore <实例ID> <文件>  恢复实例数据
  remove <实例ID>          删除实例（会询问确认）
  reset <实例ID>           重置实例（保留配置，清除数据）
  
  start-all                启动所有实例
  stop-all                 停止所有实例
  restart-all              重启所有实例
  status-all               查看所有实例状态
  backup-all               备份所有实例
  
  list                     列出所有实例
  ports                    显示端口使用情况
  validate <实例ID>        验证实例配置

示例:
  $0 status lobster-001           # 查看 lobster-001 状态
  $0 start lobster-001            # 启动 lobster-001
  $0 logs lobster-001 -f          # 实时查看日志
  $0 backup-all                   # 备份所有实例

EOF
}

# 获取实例列表
get_instances() {
    if [[ -d "$INSTANCES_DIR" ]]; then
        ls -1 "$INSTANCES_DIR" 2>/dev/null | grep -E '^lobster-[0-9]+$' | sort
    fi
}

# 检查实例是否存在
check_instance() {
    local instance_id="$1"
    if [[ ! -d "$INSTANCES_DIR/$instance_id" ]]; then
        print_error "实例 $instance_id 不存在"
        return 1
    fi
}

# 获取实例信息
get_instance_info() {
    local instance_id="$1"
    local info_file="$INSTANCES_DIR/$instance_id/instance-info.json"
    
    if [[ -f "$info_file" ]]; then
        cat "$info_file"
    else
        echo '{}'
    fi
}

# 显示实例状态
show_status() {
    local instance_id="$1"
    
    if [[ -n "$instance_id" ]]; then
        check_instance "$instance_id" || return 1
        show_single_status "$instance_id"
    else
        show_all_status
    fi
}

# 显示单个实例状态
show_single_status() {
    local instance_id="$1"
    local container_name="openclaw-$instance_id"
    local info=$(get_instance_info "$instance_id")
    
    print_header "========================================"
    print_header "实例: $instance_id"
    print_header "========================================"
    
    # 基本信息
    local name=$(echo "$info" | grep -o '"name": "[^"]*"' | cut -d'"' -f4)
    local role=$(echo "$info" | grep -o '"role": "[^"]*"' | cut -d'"' -f4)
    local emoji=$(echo "$info" | grep -o '"emoji": "[^"]*"' | cut -d'"' -f4)
    local port=$(echo "$info" | grep -o '"port": [0-9]*' | grep -o '[0-9]*')
    
    echo -e "${BLUE}基本信息:${NC}"
    echo "  名称: ${name:-未知} ${emoji}"
    echo "  角色: ${role:-未知}"
    echo "  端口: ${port:-未知}"
    
    # 容器状态
    echo ""
    echo -e "${BLUE}容器状态:${NC}"
    
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        print_success "  运行中"
        
        # 获取运行时间
        local uptime=$(docker ps --filter "name=$container_name" --format '{{.RunningFor}}')
        echo "  运行时间: $uptime"
        
        # 获取健康状态
        local health=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "N/A")
        echo "  健康状态: $health"
        
        # 获取资源使用
        local stats=$(docker stats --no-stream --format 'CPU: {{.CPUPerc}}, MEM: {{.MemUsage}}' "$container_name" 2>/dev/null || echo "N/A")
        echo "  资源使用: $stats"
        
    elif docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        print_warning "  已停止"
        
        # 获取退出码
        local exit_code=$(docker inspect --format='{{.State.ExitCode}}' "$container_name" 2>/dev/null || echo "N/A")
        echo "  退出码: $exit_code"
    else
        print_error "  未创建"
    fi
    
    # 访问地址
    echo ""
    echo -e "${BLUE}访问地址:${NC}"
    echo "  控制面板: http://localhost:${port}"
    
    # 数据目录大小
    echo ""
    echo -e "${BLUE}数据目录:${NC}"
    local dir_size=$(du -sh "$INSTANCES_DIR/$instance_id" 2>/dev/null | cut -f1)
    echo "  大小: $dir_size"
    echo "  路径: $INSTANCES_DIR/$instance_id"
}

# 显示所有实例状态
show_all_status() {
    local instances=$(get_instances)
    
    if [[ -z "$instances" ]]; then
        print_warning "没有找到任何实例"
        return
    fi
    
    print_header "========================================"
    print_header "所有实例状态"
    print_header "========================================"
    echo ""
    
    printf "%-15s %-12s %-8s %-10s %-20s\n" "实例ID" "状态" "端口" "角色" "名称"
    echo "--------------------------------------------------------------------"
    
    while IFS= read -r instance_id; do
        local container_name="openclaw-$instance_id"
        local info=$(get_instance_info "$instance_id")
        local name=$(echo "$info" | grep -o '"name": "[^"]*"' | cut -d'"' -f4)
        local role=$(echo "$info" | grep -o '"role": "[^"]*"' | cut -d'"' -f4)
        local port=$(echo "$info" | grep -o '"port": [0-9]*' | grep -o '[0-9]*')
        
        local status
        if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
            status="${GREEN}运行中${NC}"
        elif docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
            status="${YELLOW}已停止${NC}"
        else
            status="${RED}未创建${NC}"
        fi
        
        printf "%-15s %-20s %-8s %-10s %-20s\n" "$instance_id" "$status" "${port:-N/A}" "${role:-N/A}" "${name:-N/A}"
    done <<< "$instances"
    
    echo ""
    print_info "提示: 使用 '$0 status <实例ID>' 查看详细信息"
}

# 启动实例
start_instance() {
    local instance_id="$1"
    check_instance "$instance_id" || return 1
    
    print_info "启动实例 $instance_id..."
    docker compose -f "$COMPOSE_FILE" up -d "openclaw-$instance_id"
    print_success "实例 $instance_id 已启动"
}

# 停止实例
stop_instance() {
    local instance_id="$1"
    check_instance "$instance_id" || return 1
    
    print_info "停止实例 $instance_id..."
    docker compose -f "$COMPOSE_FILE" stop "openclaw-$instance_id"
    print_success "实例 $instance_id 已停止"
}

# 重启实例
restart_instance() {
    local instance_id="$1"
    check_instance "$instance_id" || return 1
    
    print_info "重启实例 $instance_id..."
    docker compose -f "$COMPOSE_FILE" restart "openclaw-$instance_id"
    print_success "实例 $instance_id 已重启"
}

# 查看日志
show_logs() {
    local instance_id="$1"
    shift
    check_instance "$instance_id" || return 1
    
    docker compose -f "$COMPOSE_FILE" logs "$@" "openclaw-$instance_id"
}

# 进入容器shell
enter_shell() {
    local instance_id="$1"
    check_instance "$instance_id" || return 1
    
    docker compose -f "$COMPOSE_FILE" exec "openclaw-$instance_id" /bin/bash
}

# 编辑配置
edit_config() {
    local instance_id="$1"
    check_instance "$instance_id" || return 1
    
    local config_file="$INSTANCES_DIR/$instance_id/config/openclaw.json"
    
    if [[ -z "$EDITOR" ]]; then
        EDITOR="vi"
    fi
    
    $EDITOR "$config_file"
}

# 备份实例
backup_instance() {
    local instance_id="$1"
    check_instance "$instance_id" || return 1
    
    local backup_dir="$BASE_DIR/backups"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/${instance_id}_${timestamp}.tar.gz"
    
    mkdir -p "$backup_dir"
    
    print_info "备份实例 $instance_id..."
    tar -czf "$backup_file" -C "$INSTANCES_DIR" "$instance_id"
    print_success "备份完成: $backup_file"
}

# 恢复实例
restore_instance() {
    local instance_id="$1"
    local backup_file="$2"
    
    if [[ ! -f "$backup_file" ]]; then
        print_error "备份文件不存在: $backup_file"
        return 1
    fi
    
    if [[ -d "$INSTANCES_DIR/$instance_id" ]]; then
        print_warning "实例 $instance_id 已存在，将覆盖"
        read -p "确认继续? (y/N): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            print_info "取消恢复"
            return
        fi
        rm -rf "$INSTANCES_DIR/$instance_id"
    fi
    
    print_info "恢复实例 $instance_id..."
    tar -xzf "$backup_file" -C "$INSTANCES_DIR"
    print_success "恢复完成"
}

# 删除实例
remove_instance() {
    local instance_id="$1"
    check_instance "$instance_id" || return 1
    
    print_warning "警告: 这将永久删除实例 $instance_id 及其所有数据!"
    read -p "确认删除? 输入实例ID确认 ($instanceID): " confirm
    
    if [[ "$confirm" != "$instance_id" ]]; then
        print_info "取消删除"
        return
    fi
    
    # 停止并删除容器
    docker compose -f "$COMPOSE_FILE" rm -sf "openclaw-$instance_id" 2>/dev/null || true
    
    # 删除数据目录
    rm -rf "$INSTANCES_DIR/$instance_id"
    
    print_success "实例 $instance_id 已删除"
}

# 重置实例
reset_instance() {
    local instance_id="$1"
    check_instance "$instance_id" || return 1
    
    print_warning "警告: 这将清除实例 $instance_id 的所有运行时数据（会话、日志等），但保留配置!"
    read -p "确认重置? (y/N): " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_info "取消重置"
        return
    fi
    
    # 停止容器
    docker compose -f "$COMPOSE_FILE" stop "openclaw-$instance_id" 2>/dev/null || true
    
    # 清除数据目录
    local data_dir="$INSTANCES_DIR/$instance_id/data"
    if [[ -d "$data_dir" ]]; then
        rm -rf "$data_dir"/*
    fi
    
    print_success "实例 $instance_id 已重置"
    print_info "使用 '$0 start $instance_id' 重新启动"
}

# 启动所有实例
start_all() {
    print_info "启动所有实例..."
    docker compose -f "$COMPOSE_FILE" up -d
    print_success "所有实例已启动"
}

# 停止所有实例
stop_all() {
    print_info "停止所有实例..."
    docker compose -f "$COMPOSE_FILE" stop
    print_success "所有实例已停止"
}

# 重启所有实例
restart_all() {
    print_info "重启所有实例..."
    docker compose -f "$COMPOSE_FILE" restart
    print_success "所有实例已重启"
}

# 备份所有实例
backup_all() {
    local instances=$(get_instances)
    
    if [[ -z "$instances" ]]; then
        print_warning "没有找到任何实例"
        return
    fi
    
    print_info "备份所有实例..."
    while IFS= read -r instance_id; do
        backup_instance "$instance_id"
    done <<< "$instances"
    print_success "所有实例备份完成"
}

# 列出实例
list_instances() {
    local instances=$(get_instances)
    
    if [[ -z "$instances" ]]; then
        print_warning "没有找到任何实例"
        return
    fi
    
    print_header "实例列表:"
    echo ""
    
    while IFS= read -r instance_id; do
        local info=$(get_instance_info "$instance_id")
        local name=$(echo "$info" | grep -o '"name": "[^"]*"' | cut -d'"' -f4)
        local role=$(echo "$info" | grep -o '"role": "[^"]*"' | cut -d'"' -f4)
        
        echo "  $instance_id - ${name:-未知} (${role:-未知})"
    done <<< "$instances"
}

# 显示端口使用
show_ports() {
    print_header "端口使用情况:"
    echo ""
    
    local instances=$(get_instances)
    
    if [[ -z "$instances" ]]; then
        print_warning "没有找到任何实例"
        return
    fi
    
    printf "%-15s %-8s %-15s\n" "实例ID" "端口" "状态"
    echo "----------------------------------------"
    
    while IFS= read -r instance_id; do
        local info=$(get_instance_info "$instance_id")
        local port=$(echo "$info" | grep -o '"port": [0-9]*' | grep -o '[0-9]*')
        
        local port_status
        if lsof -Pi :"$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
            port_status="${GREEN}已占用${NC}"
        else
            port_status="${YELLOW}空闲${NC}"
        fi
        
        printf "%-15s %-8s %-20s\n" "$instance_id" "${port:-N/A}" "$port_status"
    done <<< "$instances"
}

# 验证实例配置
validate_instance() {
    local instance_id="$1"
    check_instance "$instance_id" || return 1
    
    print_info "验证实例 $instance_id 配置..."
    
    local errors=0
    
    # 检查必需文件
    local required_files=(
        "config/openclaw.json"
        "workspace/SOUL.md"
        "workspace/IDENTITY.md"
        "workspace/USER.md"
        "workspace/AGENTS.md"
    )
    
    for file in "${required_files[@]}"; do
        if [[ -f "$INSTANCES_DIR/$instance_id/$file" ]]; then
            print_success "  ✓ $file"
        else
            print_error "  ✗ $file 缺失"
            ((errors++))
        fi
    done
    
    # 检查 JSON 配置
    if [[ -f "$INSTANCES_DIR/$instance_id/config/openclaw.json" ]]; then
        if python3 -m json.tool "$INSTANCES_DIR/$instance_id/config/openclaw.json" >/dev/null 2>&1; then
            print_success "  ✓ openclaw.json 格式正确"
        else
            print_error "  ✗ openclaw.json JSON格式错误"
            ((errors++))
        fi
    fi
    
    # 检查端口
    local info=$(get_instance_info "$instance_id")
    local port=$(echo "$info" | grep -o '"port": [0-9]*' | grep -o '[0-9]*')
    
    if [[ -n "$port" ]]; then
        if [[ "$port" -ge 1024 && "$port" -le 65535 ]]; then
            print_success "  ✓ 端口号 $port 在有效范围内"
        else
            print_error "  ✗ 端口号 $port 无效"
            ((errors++))
        fi
    fi
    
    echo ""
    if [[ $errors -eq 0 ]]; then
        print_success "验证通过，配置正确!"
    else
        print_error "发现 $errors 个问题，请修复后再启动"
        return 1
    fi
}

# 主函数
main() {
    local command="$1"
    shift || true
    
    case "$command" in
        status)
            show_status "$@"
            ;;
        start)
            start_instance "$@"
            ;;
        stop)
            stop_instance "$@"
            ;;
        restart)
            restart_instance "$@"
            ;;
        logs)
            show_logs "$@"
            ;;
        shell)
            enter_shell "$@"
            ;;
        config)
            edit_config "$@"
            ;;
        backup)
            backup_instance "$@"
            ;;
        restore)
            restore_instance "$@"
            ;;
        remove)
            remove_instance "$@"
            ;;
        reset)
            reset_instance "$@"
            ;;
        start-all)
            start_all
            ;;
        stop-all)
            stop_all
            ;;
        restart-all)
            restart_all
            ;;
        status-all)
            show_all_status
            ;;
        backup-all)
            backup_all
            ;;
        list)
            list_instances
            ;;
        ports)
            show_ports
            ;;
        validate)
            validate_instance "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
