# LSI Design Contest 2026  
## FPGA-based Generator Architecture with AXI-LITE Control

---
## Team Information

チーム名：未定  
学校名：千葉大学院　融合理工学府　基幹工学専攻
住所：〒263-8522 千葉県千葉市稲毛区弥生町1-33 千葉大学 西千葉キャンパス 工学系総合研究棟2   

## Team member

|学年|氏名|研究室|
|:---|:---|:---|
|M1|藤間 裕大|伊藤・下馬場・王研究室|
|M1|美谷 佳寛|伊藤・下馬場・王研究室|
|M1|小野 佳祐|伊藤・下馬場・王研究室|
|M1|土居 遼太郎|森田・角江研究室|

## Overview

本リポジトリは、LSIデザインコンテスト2026に向けて設計した  
**AXI-LITE 制御型 FPGA Generator アーキテクチャ**をまとめたものである。

本設計では、複雑な計算手順を PS（Python）側で管理し、  
PL（FPGA）側は計算処理に専念する **PS–PL 協調設計**を採用している。

---

## System Architecture

まず、本システム全体の構成を図に示す。

<img src="figure/arch_lsi.png" width="100%">
<p align="center">Fig. 1 System architecture</p>

本システムは、PS（Processing System）と PL（Programmable Logic）から構成される。

PL 側には以下の回路が実装されている。

- AXI-LITE 制御モジュール  
- 入力用 FIFO（FIFO-A）  
- 重み用 FIFO（FIFO-C）  
- 出力用 FIFO（FIFO-B）  
- Input Signal Concatenator  
- Output Signal Concatenator  
- Generator（計算回路）  

PS 側は AXI-LITE を介して制御信号とデータを送信し、  
計算結果は FIFO-B を通じて PS 側に返却される。

---

## AXI-LITE Control Module

次に、PS–PL 間通信を担う AXI-LITE モジュールの構成を示す。

<img src="figure/AXILITE.png" width="90%">
<p align="center">Fig. 2 AXI-LITE module structure</p>

AXI-LITE は ARM が策定したバス規格であり、  
メモリマップド I/O によるシンプルな制御を可能とする。

本設計では AXI-LITE を用いることで、

- レジスタ単位での制御  
- 計算進捗の可視化  
- Python による柔軟なシーケンス制御  

を実現している。

---

## AXI-LITE Register Map

AXI-LITE を通じた制御は、以下のレジスタマップに基づいて行われる。

### slv_reg0（制御レジスタ）

| bit | 内容 |
|---|---|
| 0 | リセット信号（Active Low） |
| 1 | 計算開始信号 |
| 2 | データ送信先 FIFO 選択 |
| 3–4 | 計算層選択 |

### slv_reg1（ステータスレジスタ）

| bit | 内容 |
|---|---|
| 0 | 全計算終了 |
| 1 | 1層計算終了 |
| 2 | 1出力計算終了 |

この構成により、PS 側は PL の状態を逐次確認しながら  
安全に計算制御を行うことができる。

---

## Processing Flow (One Layer Example)

ここでは、1 層分の計算手順を例に、  
PS 側からの制御フローを示す。

1. 入力データ送信のため `slv_reg0 = 00001` を設定  
2. 計算開始信号を立て、入力を Generator 内 RAM に格納  
3. 重みデータ送信のため `slv_reg0 = 00101` を設定  
4. 計算開始信号を立て、重みを RAM に格納  
5. `slv_reg1 == 100` となるまで PS 側は待機  
6. 上記操作を 512 回繰り返すことで 1 層の計算が完了  

---

## FIFO Structure

本設計では、用途ごとに FIFO を分離している。

- FIFO-A：入力データ  
- FIFO-C：重みデータ  
- FIFO-B：出力データ  

FIFO を分離することで、  
データ転送と計算処理の競合を防ぎ、  
安定した動作を実現している。

---

## Input / Output Signal Concatenator

<img src="figure/inoutdata.png" width="90%">
<p align="center">Fig. 5 Input / Output signal concatenator</p>

### Input Signal Concatenator

FIFO-A から送られる 32bit データを結合し、  
Generator に対して **1 クロックで必要な入力を供給**する。

### Output Signal Concatenator

Generator から出力される  
`32 × 32 × 8 bit` のデータを 32bit 単位に分割し、  
AXI-LITE 通信に適した形で PS 側に送信する。

---

## Generator Architecture

<img src="figure/image_top_module_new.png" width="100%">
<p align="center">Fig. 6 Generator internal architecture</p>

Generator は本設計の計算中核であり、  
入力データと重みデータを用いて各層の演算を行う。

制御信号は AXI-LITE から独立しており、  
計算回路は演算処理のみに集中できる構成となっている。

---

## Design Concept

本設計の設計思想は以下の通りである。

- 制御は PS、演算は PL に明確に分離  
- AXI-LITE による高い可視性  
- FIFO を用いた疎結合設計  
- 層数や構成変更への拡張性  

---

## Summary

本リポジトリでは、  
AXI-LITE を用いた FPGA Generator アーキテクチャを提案・実装した。

README 単体で  
- 構成  
- 制御方法  
- 設計意図  

が理解できることを目的とした構成となっている。
Genetratoの学習過程や、詳細な回路設計、シミュレーションや実機実装評価についてはdocディレクトリの予稿を確認されたい。