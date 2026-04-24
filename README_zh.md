# syslogFUI 实时日志查看器

[![MIT License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Repo](https://img.shields.io/badge/GitHub-sky5454/syslogFUI-green.svg)](https://github.com/sky5454/syslogFUI)

高性能实时 syslog 查看器桌面应用，支持 100,000+ 消息虚拟化滚动显示。

![alt text](docs/image.png)

## 功能特性

- 支持 UDP/TCP 协议接收实时 syslog
- 高性能虚拟化列表，支持 10 万+ 消息流畅滚动
- 按严重级别着色（紧急/警报/严重=红色，错误=橙色，警告=黄色，通知=蓝色，信息=灰色，调试=绿色）
- 暗色主题，高对比度
- 支持按严重级别、设施、搜索文本过滤
- 导出日志到 CSV
- Go 后端与 Flutter 前端之间通过 WebSocket 通信

## 架构

```
Syslog (UDP/TCP) → Go 后端 → WebSocket → Flutter 应用 → UI
```

- **Go 后端**: 使用 `gopkg.in/mcuadros/go-syslog.v2` 的 Syslog 服务器，使用 `gorilla/websocket` 处理 WebSocket
- **Flutter 前端**: BLoC 状态管理，虚拟化 ListView 保证性能

## 使用说明

### 运行已编译的应用

```bash
# Release 版本
build\windows\x64\runner\Release\syslog_viewer.exe

# Debug 版本
build\windows\x64\runner\Debug\syslog_viewer.exe
```

### 发送测试 Syslog 消息

使用系统 `logger` 命令或内置测试客户端：

```bash
# 通过 TCP 发送
logger -ntcp -p local0.info "测试消息"

# 通过 UDP 发送
logger -nudp -p local0.info "测试消息"
```

或使用测试客户端（需先编译）：
```bash
go run ./go/clientTest --server=localhost:514 --protocol=tcp --threads=4 --count=100
```

参数说明：
- `--server`: 服务器地址（默认 localhost:514）
- `--protocol`: 协议类型 tcp/udp/all（默认 tcp）
- `--threads`: 并发线程数（默认 4）
- `--count`: 每线程消息数（默认 100）

### 配置

点击状态栏右侧的地址可修改：
- **Syslog 地址**: 默认 `localhost:514`
- **WebSocket URL**: 默认 `ws://localhost:8765/ws`

## 从源码编译

### 环境要求

- Go 1.21+
- Flutter SDK 3.0+
- Windows 10/11

### 一键构建

在项目根目录执行：

```bash
dart run ./build.dart
```

构建脚本会依次：
1. 编译 Go 后端 → `go/bin/syslog_viewer.exe`
2. 复制到 Flutter 构建目录
3. 构建 Flutter 应用

### 手动编译

#### 编译 Go 后端

```bash
cd go
go build -o bin/syslog_viewer.exe .
go build -o bin/clientTest.exe ./clientTest/
```

#### 编译 Flutter

```bash
flutter build windows --release
# 或编译 Debug 版本：
flutter build windows --debug
```

### 构建产物

| 文件 | 位置 |
|------|------|
| Go 后端 | `go/bin/syslog_viewer.exe` |
| Flutter Release | `build/windows/x64/runner/Release/syslog_viewer.exe` |
| Flutter Debug | `build/windows/x64/runner/Debug/syslog_viewer.exe` |

## 项目结构

```
syslog_flutter_gui/
├── go/                          # Go 后端
│   ├── main.go                  # 入口点
│   ├── go.mod                   # Go 模块
│   ├── message/                 # 消息类型定义
│   ├── channel/                 # 消息广播和环形缓冲区
│   ├── syslog/                  # Syslog UDP/TCP 服务器
│   ├── websocket/               # WebSocket 处理器
│   ├── http/                    # HTTP 服务器（WebSocket 升级）
│   ├── mcp/                     # MCP 协议（AI 接入）
│   └── clientTest/              # 测试用 syslog 客户端
│
├── lib/                         # Flutter 应用
│   ├── main.dart
│   ├── bloc/                    # BLoC 状态管理
│   ├── models/                  # 数据模型
│   ├── services/                # WebSocket 和后端服务
│   ├── widgets/                 # UI 组件
│   └── theme/                   # 应用主题
│
├── build.dart                   # 构建脚本
└── pubspec.yaml                 # Flutter 依赖
```

## Go 后端命令行参数

```bash
./syslog_viewer.exe [选项]

选项:
  --syslog=<地址>   Syslog 服务器地址（默认: localhost:514）
  --protocol=<协议> 协议: udp, tcp, 或 all（默认: all）
  --http=<地址>     HTTP/WebSocket 服务器地址（默认: localhost:8765）
```

## MCP 协议（AI 接入）

Go 后端在 `http://localhost:8765/mcp/` 提供 MCP 兼容的 HTTP API，方便 AI 接入分析日志。

### 端点

| 端点 | 方法 | 说明 |
|------|------|------|
| `/mcp` | POST | JSON-RPC 2.0 MCP 协议端点 |
| `/mcp/tools` | GET | 列出可用工具 |
| `/mcp/query` | POST | 直接查询日志 |

### 可用工具

#### query_logs
带可选过滤器查询 syslog 消息。

```json
POST /mcp/query
{
  "limit": 100,
  "severity": "error",
  "keyword": "failed",
  "host": "server1"
}
```

参数：
- `limit` (number): 最大返回消息数（默认: 100，最大: 1000）
- `severity` (string): 按严重级别过滤（emergency, alert, critical, error, warning, notice, info, debug）
- `keyword` (string): 在消息内容中搜索
- `host` (string): 按主机名过滤

#### get_statistics
获取日志统计信息。

```json
POST /mcp
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "get_statistics"
  }
}
```

返回：总数量、按级别统计、按设施统计、缓冲区容量。

### 示例：Claude Desktop 集成

添加到 Claude Desktop 配置：

```json
{
  "mcpServers": {
    "syslog-viewer": {
      "command": "curl",
      "args": [
        "-X", "POST",
        "-H", "Content-Type: application/json",
        "-d", '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"query_logs","arguments":{"limit":50}},"id":1}',
        "http://localhost:8765/mcp"
      ]
    }
  }
}
```

### 直接查询示例

```bash
# 查询最近 50 条错误消息
curl -X POST http://localhost:8765/mcp/query \
  -H "Content-Type: application/json" \
  -d '{"limit": 50, "severity": "error"}'

# 获取统计信息
curl http://localhost:8765/mcp/tools
```

## GitHub Actions CI/CD

项目包含 GitHub Actions 工作流，支持自动化构建和发布。

### 工作流

| 工作流 | 触发条件 | 说明 |
|--------|----------|------|
| `ci.yml` | 推送到 main/PR | 运行测试和快速构建 |
| `release.yml` | Git 标签 `v*` | 构建所有平台并创建 release |

### CI 流水线

每次推送到 `main`/`master` 或 PR 时：
- 运行 Go 测试和代码检查
- 运行 Flutter 分析和测试
- 快速构建 Go 二进制文件
- 快速构建 Flutter Windows

### Release 流水线

每次打 Git 标签 `v*` 时：
- 构建 Go 二进制：Windows (amd64, arm64)、Linux (amd64, arm64)、macOS (amd64, arm64)
- 构建 Flutter Windows 桌面应用
- 创建发布包 (.zip, .tar.gz)
- 上传到 GitHub Releases（草稿）

### 使用方法

1. 推送到 GitHub
2. 在 Actions 标签页查看 CI 运行
3. 创建 Release：
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
4. 在 Releases 页面发布草稿

### 手动触发

也可以从 GitHub Actions 页面手动触发 release 工作流。

## 界面说明

| 组件 | 说明 |
|------|------|
| 工具栏（顶部） | 启动/停止服务器、清除日志、导出 CSV、自动滚动开关 |
| 过滤面板（左侧） | 严重级别复选框、设施过滤、搜索框 |
| 日志显示区（中央） | 虚拟化日志表格，显示时间戳、主机、级别、消息 |
| 状态栏（底部） | 连接状态、消息计数、级别分布、可点击修改的地址 |

## 故障排除

### 没有收到消息
- 确保发送方使用 TCP（Windows UDP 回环可能被阻止）
- 检查防火墙设置
- 确认 syslog 地址与发送方配置一致

### 构建失败
- 执行 `flutter clean` 后重新构建
- 确保 Go 和 Flutter 已正确安装
- 检查端口 514 和 8765 是否被占用
