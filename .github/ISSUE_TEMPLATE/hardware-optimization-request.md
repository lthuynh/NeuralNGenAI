---
name: Hardware Optimization Request
about: Request optimization for Apple Silicon hardware
title: '"[HARDWARE] "'
labels: ai-context, hardware, optimization
assignees: ''

---

name: Hardware Optimization Request
description: Request optimization for Apple Silicon hardware
title: "[HARDWARE] "
labels: ["hardware", "optimization", "ai-context"]
body:
  - type: markdown
    attributes:
      value: |
        ## Hardware Optimization Context
        This template captures context for AI assistants to implement hardware optimizations.

  - type: dropdown
    id: hardware-target
    attributes:
      label: Target Hardware
      description: Which Apple Silicon chip are you targeting?
      options:
        - M1/M1 Pro/M1 Max
        - M2/M2 Pro/M2 Max
        - M3/M3 Pro/M3 Max
        - M4/M4 Pro/M4 Max
        - A15 Bionic or newer
        - All Apple Silicon
    validations:
      required: true

  - type: dropdown
    id: optimization-type
    attributes:
      label: Optimization Type
      multiple: true
      options:
        - Neural Engine utilization
        - Metal shader optimization
        - Memory bandwidth optimization
        - Thermal management
        - Battery efficiency
        - TBDR optimization
    validations:
      required: true

  - type: textarea
    id: current-performance
    attributes:
      label: Current Performance Metrics
      description: Provide baseline measurements
      placeholder: |
        - Current FPS: 45
        - Neural Engine utilization: 30%
        - Memory usage: 800MB
        - Battery drain: 15% per hour

  - type: textarea
    id: optimization-goals
    attributes:
      label: Optimization Goals
      description: Specific, measurable targets
      placeholder: |
        - Achieve 60 FPS consistently
        - Increase Neural Engine utilization to >80%
        - Reduce memory usage by 40%
        - Reduce battery drain to <10% per hour

  - type: textarea
    id: relevant-code
    attributes:
      label: Relevant Code Paths
      description: Files and functions to optimize
      placeholder: |
        - Sources/Hardware/MetalRenderer.swift
        - Sources/Models/InferenceEngine.swift
        - Pattern to follow: examples/metal-compute-pattern.swift

  - type: checkboxes
    id: requirements
    attributes:
      label: Optimization Requirements
      options:
        - label: Maintain API compatibility
        - label: Support all target platforms
        - label: Include performance tests
        - label: Update documentation
        - label: Add profiling markers
