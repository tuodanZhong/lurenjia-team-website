# dsh-test-coverage · 测试覆盖率分析：解析 LCOV / Cobertura / Istanbul-JSON / Go cover

[![npm](https://img.shields.io/npm/v/dsh-test-coverage)](https://www.npmjs.com/package/dsh-test-coverage)
[![GitHub](https://img.shields.io/github/stars/uckkk/dsh-test-coverage)](https://github.com/uckkk/dsh-test-coverage)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

测试覆盖率分析：解析 LCOV / Cobertura / Istanbul-JSON / Go cover。纯 Node 实现，零第三方运行时依赖，peer-only 依赖（随 DSH 宿主加载）。
测试覆盖率分析：解析 LCOV / Cobertura / Istanbul-JSON / Go cover — a [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (dsh) plugin. Pure Node, zero runtime dependencies.

## 工具 Tools

- `coverage_report`
- `coverage_gaps`

## 安装 Install

```sh
dsh plugin --profile web add dsh-test-coverage
# 或任意 profile：dsh plugin --profile <name> add dsh-test-coverage
```

## License

MIT © istone
