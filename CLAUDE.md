# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

clax は Common Lisp から OpenXLA (PJRT API) を利用するための FFI インターフェースライブラリ。CFFI を通じて C++ ラッパー共有ライブラリ (`libxla_wrapper.so`) を呼び出し、XLA のテンソル演算を Common Lisp から実行する。

## Build & Run

### C++ 共有ライブラリのビルド (Bazel)
```bash
cd xla
bazel build //xla/lisp_bridge:libxla_wrapper.so
```
ビルド成果物: `xla/bazel-bin/xla/lisp_bridge/libxla_wrapper.so`

### Common Lisp パッケージのロード
```lisp
;; Quicklisp 経由でロード (~/quicklisp/local-projects/ に配置済み)
(ql:quickload :clax)

;; FFI バインディングの直接ロード (ASDF 外)
(load "cffi.lisp")

;; テスト実行
(test-run)
```

### デバッグログ
C++ ラッパーは `/tmp/xla_debug.log` にデバッグログを出力する。

## Architecture

### レイヤー構成

```
Common Lisp (cffi.lisp)
    ↓ CFFI
C++ wrapper (xla/xla/lisp_bridge/xla_wrapper.cpp)
    ↓
PJRT C API (OpenXLA)
```

### 主要ファイル

- `clax.asd` — ASDF システム定義。依存: `cffi`
- `package.lisp` — `clax` パッケージ定義 (export: `initialize-client`, `shutdown-client`)
- `clax.lisp` — PJRT CPU プラグインの直接ロード (初期の試み、現在は cffi.lisp が主)
- `cffi.lisp` — **メインの FFI バインディング**。C++ ラッパーの全関数を定義し、Lisp 側のヘルパーマクロ・関数を提供
- `sample.lisp` — PJRT C API を CFFI で直接 (C++ ラッパーなしで) 叩く実験コード
- `xla/` — OpenXLA の git submodule (fork: KUrushi/xla)。`xla/xla/lisp_bridge/` にブリッジコードを追加

### cffi.lisp の主要 API

- `with-pjrt-api` — API の初期化・終了を管理するマクロ
- `with-pjrt-client` — クライアントの生成・破棄を管理するマクロ
- `tensor-from-host` — Common Lisp の多次元配列から PJRT バッファを生成 (`single-float`, `double-float` 対応)
- `compile-add-program` — StableHLO (MLIR) の加算プログラムをコンパイル
- `execute-add` — コンパイル済み加算プログラムを実行
- `buffer-to-host` — PJRT バッファからホストメモリへデータ転送
- `test-run` — 2x3 行列の加算を実行するデモ関数

### 注意事項

- `cffi.lisp` 内の `libxla-wrapper` のパスは絶対パスでハードコードされている
- `clax.asd` のシステム定義と `cffi.lisp` は独立して動作する (cffi.lisp は ASDF 外で直接 `load` する想定)
- xla submodule は `xla/xla/lisp_bridge/` に Bazel ビルドターゲットを持つ
