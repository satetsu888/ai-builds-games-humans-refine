# Sound Design: Chain Circuit Vault

**Visual Tags (Sound Source)**: #composition-centered-stage, #render-uniform-stroke

## 1. Audio Concept

機械的で輪郭の揃った短音を中心に、イベント意味を即判別できるドライなシンセ設計。

## 2. Waveform Palette

| Role | Waveform | Parameters | Usage |
| :--- | :--- | :--- | :--- |
| Primary tone | Square | duty 0.45, short decay | throw/score motif |
| Low alarm | Noise + sine | low freq + noise mix | damage/game over |

## 3. Semantic Timbre Mapping

- `score`: 高め square、短い上向き印象
- `danger`: 低い sine/triangle の脈動、予兆と確定で2段階分離
- `damage`: 低域 noise 混合、長め減衰
- `state change`: ルーン強化・導通開始・ジェネレーター破壊を別音色へ分解

## 4. Event SFX Specs

| Event | Timbre | Duration | Dynamic response |
| :--- | :--- | :--- | :--- |
| Throw release | Square click | 90ms | charge無関係で固定（入力認識明瞭化） |
| Rune charge | Triangle + square rise | 120ms | 強化取得だけ明るく上昇 |
| Score gain | Bright square + upper partial | 60-120ms | 連鎖数で倍音追加 |
| Cable conduction | Short square/sine ticks | 50ms/step | 通常導通と緊急導通で波形と音域を分離 |
| Spread warning | Low sine pulse | 80-100ms | 新しい予兆セル出現時のみ再生 |
| Spread confirm | Noise + low sine bloom | 160-180ms | 汚染確定でだけ再生 |
| Generator break | Square crack + falling low core | 220ms | 汚染源破壊の重さを付与 |
| Damage / game over | Noise-heavy low | 280ms | game over時に最長尾を採用 |

## 5. Dynamic Parameters

- Difficulty増加で spread イベント頻度が増え、state-change音密度が上がる。
- 高得点イベントはピッチ上昇でリスク成功を可聴化。
- 導通音はステップごとに微上昇し、広域伝搬の進行方向を耳で追えるようにする。

## 6. Continuous Sound Policy

- Continuous sound は常時採用しない。
- 理由: 盤面判断型パズルで短い情報音の識別性を優先。ただし将来改善ではジェネレーター近傍の微弱ハムは候補。

## 7. Cross-Game Variation Plan

- 前作流用を避けるため、今回は square 主体 + noise 補助で構成。
- 次回は triangle 主体やFM変調主体へ切替予定。

## 8. Checklist

- [x] score/damage/state change を耳だけで区別可能
- [x] visual tags に整合した機械的で均質な音色
- [x] 動的パラメータ（score pitch、difficulty密度）を実装
- [x] event-to-timbre mapping をゲーム内で固定
- [x] ルーン強化 / 導通 / 汚染予兆 / 汚染確定 / ジェネレーター破壊を別イベントとして可聴分離
