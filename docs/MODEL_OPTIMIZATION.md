# 模型部署优化方案

> 目标: 节省内存资源，从~10GB常驻优化到~3GB常驻

---

## 当前问题

| 问题 | 影响 |
|------|------|
| ModelScope模型Python加载后常驻内存 | bge-m3(4.3GB)+bge-large(2.4GB)=6.7GB |
| 向量模型重复 | 本地BGE + 云端DashScope |
| ASR模型常驻 | Paraformer ~1GB |

---

## 优化方案

### 1. 立即执行 (5分钟)

```bash
# 1. 下载Ollama嵌入模型 (替代BGE)
docker exec infra-ollama ollama pull nomic-embed-text

# 2. 验证
docker exec infra-ollama ollama list
```

**效果**: 可删除bge-large-zh + bge-m3 (~6.7GB)→释放

### 2. 短期优化 (今天)

| 操作 | 释放内存 | 命令 |
|------|----------|------|
| 删除BGE本地模型 | ~6.7GB | `rm -rf ~/.cache/modelscope/hub/models/AI-ModelScope/bge-*` |
| 删除BGE缓存 | ~2GB | `rm -rf ~/.cache/modelscope/hub/models/Xorbits/bge-m3` |
| Paraformer按需加载 | ~1GB | 修改代码: 用LazyLoad模式 |

### 3. 代码改造

**向量嵌入 (原BGE → Ollama):**
```python
# 旧代码 (BGE, 常驻2-4GB)
from modelscope import AutoModel
model = AutoModel.from_pretrained('bge-large-zh')

# 新代码 (Ollama, 用时加载, 用完释放)
import requests
def get_embedding(text):
    r = requests.post('http://localhost:11434/api/embeddings', 
        json={'model': 'nomic-embed-text', 'prompt': text})
    return r.json()['embedding']
```

**LLM推理 (本地Qwen → Ollama):**
```python
# 统一走Ollama HTTP接口
def chat(messages):
    r = requests.post('http://localhost:11434/api/chat',
        json={'model': 'qwen3:4b', 'messages': messages, 'stream': False})
    return r.json()['message']['content']
```

### 4. 最终架构

```
内存占用对比:
┌────────────────┬─────────────┬─────────────┐
│ 组件            │ 优化前       │ 优化后       │
├────────────────┼─────────────┼─────────────┤
│ Docker基础服务  │ ~1.6GB      │ ~1.6GB      │
│ Ollama (空闲)   │ -           │ ~117MB      │
│ Ollama (运行)   │ -           │ 按需2-5GB   │
│ ModelScope BGE  │ ~6.7GB      │ 0 (删除)    │
│ Paraformer ASR  │ ~1GB        │ ~0.1GB(按需)│
│ PaddleX OCR     │ ~0.2GB      │ ~0.2GB      │
├────────────────┼─────────────┼─────────────┤
│ 常驻总计        │ ~9.5GB      │ ~2GB        │
│ 峰值 (推理时)   │ ~9.5GB      │ ~7GB        │
└────────────────┴─────────────┴─────────────┘
```

### 5. 执行脚本

```bash
#!/bin/bash
# save as: optimize_models.sh

echo "=== 模型部署优化 ==="

# 1. 确保Ollama有替代模型
echo "[1/3] 检查Ollama模型..."
docker exec infra-ollama ollama list | grep -q nomic-embed-text || {
    echo "下载nomic-embed-text..."
    docker exec infra-ollama ollama pull nomic-embed-text
}

# 2. 备份并删除BGE模型
echo "[2/3] 删除BGE本地模型..."
BACKUP_DIR=~/model_backup_$(date +%Y%m%d)
mkdir -p $BACKUP_DIR

if [ -d ~/.cache/modelscope/hub/models/AI-ModelScope ]; then
    mv ~/.cache/modelscope/hub/models/AI-ModelScope $BACKUP_DIR/
    echo "  bge-large-zh已备份"
fi

if [ -d ~/.cache/modelscope/hub/models/Xorbits ]; then
    mv ~/.cache/modelscope/hub/models/Xorbits $BACKUP_DIR/
    echo "  bge-m3已备份"
fi

# 3. 显示结果
echo "[3/3] 优化完成"
echo "备份位置: $BACKUP_DIR"
echo ""
echo "当前Ollama模型:"
docker exec infra-ollama ollama list
echo ""
echo "如需恢复: mv $BACKUP_DIR/AI-ModelScope ~/.cache/modelscope/hub/models/"
```

---

## 关键决策

| 场景 | 推荐方案 | 原因 |
|------|----------|------|
| 向量嵌入 | Ollama nomic-embed-text | 用完即卸载, 274MB vs 6.7GB |
| LLM推理 | Ollama qwen3:4b/8b | 标准化API, 可卸载 |
| OCR识别 | PaddleX本地 | 轻量210MB, 离线可用 |
| ASR语音 | Paraformer本地 | 但改为按需加载 |
| 视觉任务 | 云端qwen-vl-max | 零本地内存 |
| 多模态 | 云端glm-4v | 零本地内存 |

---

**预期效果**: 常驻内存从~10GB降至~2GB，节省~8GB。
