# dsh-screenshot-diff

> DeepSeek Harness 插件 · 像素对比 / DSH plugin for pixel-diffing screenshots

对两张已截图做像素 diff，输出 `diff.png`（差异标红）和 `compare-triple.png`（左 A / 中 B / 右 diff 三联图，各自左上角带标签）。**不做截图采集**——输入是你已有的两张图。

Pixel-diff two existing screenshots into `diff.png` (differences in red) plus a labeled triptych `compare-triple.png` (A | B | diff). It does **not** capture screenshots — you supply the two images.

## 使用 Usage

```bash
bash scripts/diff.sh /abs/path/imgA.png /abs/path/imgB.png \
  --label-a before \
  --label-b after \
  --sensitivity high \
  --out /tmp/diff-out
```

| 参数 | 说明 |
|---|---|
| `--out DIR` | 输出目录，默认第一张图所在目录 |
| `--label-a/--label-b TEXT` | 左右图标签，默认 `a` / `b` |
| `--sensitivity LEVEL` | `normal`（灰度+阈值0.1+忽略抗锯齿，稳）/ `high`（彩色+阈值0.02+计入抗锯齿）/ `ultra`（阈值0.01，最灵敏、噪点多） |
| `--threshold N` | pixelmatch 阈值，显式传入覆盖灵敏度预设 |
| `--crop-top PX` | 两图同时裁掉顶部物理像素 |
| `--compare-tool DIR` | sharp/pngjs/pixelmatch 依赖目录，或设 `COMPARE_TOOL_ENV` |

依赖自动发现：`--compare-tool` > `COMPARE_TOOL_ENV` > 仓库内 `scripts/compare-tool`。依赖为 `sharp` / `pngjs` / `pixelmatch`。

## 输出 Output

```text
<out>/diff.png            差异标红（[255,0,0]）
<out>/compare-triple.png  三联图：左 A | 中 B | 右 diff <相似度>
```

stdout 输出 JSON：`similarity`、`numDiffPixels`、`total`、`sensitivity`、`threshold`。

## 判读 Judgment

- **相似度 ≠ 结论**：90% 以上的"大体一致"也要人工看 diff 区是否集中在应改位置。
- **先用 `normal`** 跑一版；要抓淡灰/白渐变这类低对比差异再升 `high`；`ultra` 噪点最多，慎用。
- **尺寸不一致直接失败**，不会被拉伸掩盖布局问题——这是刻意设计。
- 两张图必须同一视口/分辨率、同一页面状态（滚动位置、弹窗、加载态），否则 diff 无意义。

## 安装 Install

```sh
# 发布到 npm 后
dsh plugin --profile demo add dsh-screenshot-diff

# 或从 GitHub 安装
dsh plugin --profile demo add github:PangYiMing/dsh-screenshot-diff
```

## 许可证 License

[MIT](./LICENSE)
