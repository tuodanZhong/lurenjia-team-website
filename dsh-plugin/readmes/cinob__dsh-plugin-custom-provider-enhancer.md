# DSH Custom Provider Enhancer (自定义提供商参数增强插件)

[![DSH Plugin](https://img.shields.io/badge/DSH-Plugin-5B4CF0?style=flat-square)](https://github.com/AdamPlatin123/awesome-dsh-plugins)
[![Cordis 3.x](https://img.shields.io/badge/Cordis-3.x-blue?style=flat-square)](https://cordis.moe)
[![License: MIT](https://img.shields.io/badge/license-MIT-0B7285?style=flat-square)](LICENSE)
[![Node.js](https://img.shields.io/badge/Node.js-%5E20.0%20%7C%20%5E22.0%20%7C%20%3E%3D24-339933?style=flat-square&logo=nodedotjs&logoColor=white)](package.json)
[![Verified Tests](https://img.shields.io/badge/verified-5%20tests-2EA44F?style=flat-square)](tests)

[English](README.md) | 简体中文

**DSH Custom Provider Enhancer** 是专为 DeepSeek Harness (DSH) / Cordis 插件生态打造的**自定义模型提供商参数自动补齐与能力增强插件**。

在 Web 界面配置自定义提供商（如 OneAPI、NewAPI、OpenRouter、vLLM、Ollama 及各类 OpenAI 兼容第三方中转网关）时，自动探测可用模型，并基于 3000+ 权威大模型数据库自动补全 **上下文大小（`contextWindow`）**、**最大输出 Token（`maxTokens`）**、**视觉多模态输入（`input: [text, image]`）** 与 **深度思考强度档位（`reasoningEfforts`）**。

---

## 📋 目录
- [概述](#-概述)
- [兼容性支持](#-兼容性支持)
- [核心特性](#-核心特性)
- [安装与挂载](#安装与挂载)
- [配置说明](#-配置说明)
- [快速开始](#-快速开始)
- [权限与数据安全说明](#-权限与数据安全说明)
- [常见问题与回滚指引](#-常见问题与回滚指引)
- [本地开发与测试](#-本地开发与测试)
- [开源协议](#-开源协议)

---

## 🎯 概述

### 它解决什么问题？
当用户在 DeepSeek Harness 中接入第三方网关（OneAPI / NewAPI / vLLM / Ollama 等）时，接口标准的 `GET /models` 探测通常只返回裸模型 ID（如 `gemini-3.7-flash`、`deepseek-v4-pro` 或 `mimo-v2.5`），缺少关键的运行时参数：
- ❌ 缺失上下文大小：导致 Token 压力监控失真或上下文意外溢出；
- ❌ 缺失视觉模态声明：导致 Web 聊天对话框中无法上传图片或拖拽截图；
- ❌ 缺失思考档位声明：导致模型选择器下方无法出现思考强度调节菜单。

### 本插件如何解决？
1. **自动探测与参数富化**：拦截 `llm.discoverModels` 流程，自动为探测到的模型回填精确的上下文与输出上限；
2. **视觉与思考能力自动点亮**：拦截 `llm.resolveModelInfo` 与 `settings.mutate`，无论在运行时还是持久化 `settings.yaml` 时，均自动注入 `input: [text, image]` 与 `reasoningEfforts` 档位字典；
3. **零侵入官方通道**：仅针对用户添加的第三方自定义提供商生效，原生 DeepSeek 等官方通道保持原生行为。

---

## 🧭 兼容性支持

| 运行环境 | 支持版本 | 兼容状态 |
| :--- | :--- | :--- |
| **DeepSeek Harness (DSH)** | `0.1.0-rc.1` ~ `mainline` | ✅ 运行级验证通过 (Runtime Compatible) |
| **Cordis 插件内核** | `^3.0.0` | ✅ 完整兼容 |
| **Node.js** | `^20.0.0 || ^22.0.0 || >=24.0.0` | ✅ 完整兼容 |
| **操作系统** | Linux, macOS, Windows | ✅ 跨平台支持 |

---

## ✨ 核心特性

- ⚡ **零配置全自动**：在 Web 页面添加自定义模型或点击保存时，全自动静默完成富化。
- 📏 **精准容量识别**：Gemini 3.7 Flash 自动填入 1M 上下文 / 64K 输出，DeepSeek V4 Pro 自动填入 1000K，GPT-4o 自动填入 128K，MiMo 2.5 自动填入 256K。
- 👁️ **视觉能力自动激活**：检测到视觉多模态模型（Gemini、Claude、GPT-4o、MiMo、Qwen-VL 等）时，自动配置 `input: ['text', 'image']`，直接激活图片上传与视觉多模态分析。
- 🧠 **思考档位自动注入**：检测到推理模型（R1、o1、o3、Gemini 3.7 Flash、QwQ、Claude 3.7 等）时，自动配置 `off`、`low`、`medium`、`high`、`max` 档位，激活 Web 聊天界面的思考强度滑动菜单。
- 💾 **双层持久化与运行时覆盖**：保存时自动规范写入 `settings.yaml`；对于历史保存过的默认占位模型，在内存中动态修正。
- 🛡️ **3000+ 数据库与离线容灾**：内置 30+ 常见前沿模型保底规则，支持多源同步与 1 小时内存缓存，支持 `-20241120` 等日期快照后缀智能模糊匹配。

---

## 安装与挂载

作为标准 DSH Profile Bundle 组合包，一键安装并自动挂载：

```bash
dsh plugin --profile web add github:cinob/dsh-plugin-custom-provider-enhancer
```

> **提示**：插件自带标准 Bundle Patch，安装后系统会自动挂载并激活服务，**无需**在 `profiles/web/cordis.patch.yml` 中重复手动 insert。

### 卸载插件

```bash
dsh plugin --profile web remove dsh-plugin-custom-provider-enhancer
```

---

## ⚙️ 配置说明

如需微调行为，可在 `$DSH_HOME/profiles/web/cordis.patch.yml` 中自定义配置（可选）：

```yaml
- id: custom-provider-enhancer
  config:
    # 远程模型元数据源
    metadataUrl: https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json
    # 请求超时时间（毫秒，默认 5000ms）
    timeoutMs: 5000
    # 内存缓存过期时间（毫秒，默认 1 小时）
    cacheTtlMs: 3600000
    # 未知模型的保底上下文大小（默认 128000）
    defaultContextWindow: 128000
    # 未知模型的保底最大输出 Token（默认 4096）
    defaultMaxTokens: 4096
```

---

## ⚡ 快速开始

1. 启动 DSH Web 界面（`dsh web`）；
2. 点击 **设置 ➔ 模型 ➔ 添加提供商**；
3. 填入自定义端点的 Base URL 和 API Key，点击 **获取可用模型**；
4. 勾选所需模型点击 **采纳**，然后点击 **保存**；
5. 所有参数（`contextWindow`、`maxTokens`、`input`、`reasoningEfforts`）均已全自动完善并保存！

---

## 🔒 权限与数据安全说明

- **网络访问声明**：插件仅向用户显式填写的自定义网关发起 `GET /models` 探测，并向公开的大模型规格数据库（LiteLLM GitHub）拉取公开只读数据；
- **零凭据泄露风险**：API Key 仅在用户手动发起探测请求时作为标准 Header 传递，插件内部绝不存储、记录或转发任何用户 Key；
- **安全沙箱无害**：插件为纯 JavaScript 内存服务拦截器，不运行任何外部子进程，不修改无关文件。

---

## 🛠️ 常见问题与回滚指引

- **修改未即时显示**：
  直接在 Web 设置中点击 **“保存”**，插件会自动识别并一键补齐所有历史模型的上下文与模态。
- **快速回滚**：
  运行 `dsh plugin --profile web remove dsh-plugin-custom-provider-enhancer` 即可卸载。

---

## 💻 本地开发与测试

```bash
# 克隆仓库
git clone https://github.com/cinob/dsh-plugin-custom-provider-enhancer.git
cd dsh-plugin-custom-provider-enhancer

# 安装依赖
pnpm install

# 运行自动化测试
pnpm test

# 打包构建
pnpm build
```

---

## 📄 开源协议

[MIT License](LICENSE)
