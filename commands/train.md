---
description: Start or resume the Gemma 3 27B fine-tuning pipeline on node-a
---

## Training Pipeline Checklist

1. **Check GPU status:** Run nvidia-smi to verify GPU is free
2. **Check training container:** Is this-node-unsloth running? If not, start it
3. **Check training data:** Is ~/data/training/processed/virian_finetune.jsonl ready?
4. **Check model:** Can we load google/gemma-3-27b-it in Unsloth?

Based on what's ready, propose the next step in the pipeline.
Phases: Environment Setup → Data Prep → Fine-Tune → Export GGUF → Deploy

Use the trainer subagent for ML-specific decisions.
