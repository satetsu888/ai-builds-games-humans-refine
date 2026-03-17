# Chain Circuit Vault (chain_circuit_vault)

## Links

- [VISUAL_DESIGN.md](./VISUAL_DESIGN.md)
- [TYPOGRAPHY_DECISION.md](./TYPOGRAPHY_DECISION.md)
- [SOUND_DESIGN.md](./SOUND_DESIGN.md)
- [THIRD_PARTY_LICENSES.md](./THIRD_PARTY_LICENSES.md)
- [logs/test.json](./logs/test.json)
- [logs/improvement_report.md](./logs/improvement_report.md)

## 0. Tag Record

- Mechanism (3): #field-connected, #rule-friendly_fire, #on_released-throw
- Visual (2): #composition-centered-stage, #render-uniform-stroke
- Structure (1): #structure-irreversible_change
- button_types: 4
- Unexpected pair check: `field-connected + rule-friendly_fire` is not in `data/tags/obvious_pairs.json`

## 0.5 State Model (minimal)

| State Variable | Increase/Decrease Triggers | UI/Feedback Reflection |
| :--- | :--- | :--- |
| `corruption_tiles` | Throwの誤射、時間経過による拡散で増加。減少なし（不可逆） | 盤面タイルが赤く固定変色し、安全経路が消える |
| `difficulty_level` | 経過1分ごとに+1 | 汚染拡散間隔が短縮、盤面変化が加速 |

Notes:
- `corruption_tiles` は「未来の移動選択を恒久的に削る」意思決定を追加するため導入。

## 1. Core Mechanics

- 4ボタン(矢印キー / WASD)で中枢ノードをグリッド移動。
- ノードは過去位置を追従する連結ケーブル(5節)を持つ。
- 方向入力を離して停止すると、最後に向いていた方向へパルスが1セルずつ前進する（長押し溜めなし）。
- パルスがルーン（アイテム）に触れると、その投擲は強化状態へ遷移。
- 強化状態のパルスは赤い汚染タイルを通過時に除去できる。
- ルーンは強化パルス起動のトリガーであり、直接得点しない。
- 得点は強化パルスで汚染パネル/ジェネレーターを浄化した時のみ発生し、同一伝達内で `+1, +2, +3...` とコンボ加算。
- ただしパルスが自ケーブルに当たると friendly fire で汚染タイルを増やす。
- 汚染は時間で拡散し、到達領域は永久に危険化。
- 汚染はジェネレーターを含む汚染パネル群として同一ルールで拡散する（frontier拡張）。
- ジェネレーターは強化パルスで破壊でき、別位置に再配置される。
- ゲームオーバー: 中枢が汚染踏破 / 盤面崩壊。

## 1.5 Tradeoff Definition

- Concrete behavior pair: `安全に短距離投擲` vs `汚染際の高得点投擲`
- Tradeoff explanation: 高得点は汚染隣接の危険ルーンに偏るため、狙うほど誤射・拡散接触でケーブル損傷が進む。

## 2. Object Specifications

- **中枢ノード**: 白円。プレイヤー本体。汚染に触れると敗北。
- **連結ケーブル**: 青緑の導線+節点。通常は回路、強化伝搬時は通電状態として発光。
- **ルーン**: 金色の二重印章。命中した瞬間にパルスを強化し、そのセルから浄化能力を得る。
- **汚染タイル**: 赤タイル。時間で増殖する不可逆危険領域。
- **汚染ジェネレーター**: 角張った橙色炉心。汚染拡散源で、強化パルスで破壊可能。
- **パルス軌跡**: 通常は白い信号枠、強化後は青緑の十字芯と外周光に変化する。

## 3. Design Guide Analysis

- Simplicity: ルールは「移動・離し投擲・汚染回避」の3要素。
- Visual feedback: 得点/誤射/拡散/崩壊を色と形変化で即時表示。
- Skill and risk: 単純連打では得点が伸びにくく、危険地帯狙いでのみ高得点。
- Novelty: 「自分の連結体を撃って盤面が永久に壊れる」自己干渉パズル。

## 4. Relationship with Tags

- `field-connected`: プレイヤー軌跡がケーブルとして連結維持。
- `rule-friendly_fire`: 投擲が自ケーブルにも有効。
- `on_released-throw`: 入力解放（停止）をトリガに段階伸長で発射。
- `structure-irreversible_change`: 汚染タイルが永続蓄積。
- visual tags: 中央ステージ構図 + 均一線幅で抽象盤面を可読化。

## 5. Basis for Novelty

既存の「弾を避ける」系と異なり、本作は**自分の行動履歴(ケーブル形状)が将来の誤射対象**になる。さらに誤射結果が汚染として残るため、毎投擲が盤面設計のコミットになる。

## 6. Phase 7 Improvement Options (Evaluation Only)

### Option A (operators: State reduction + Integrate into world representation)

- Integrate hazard feedback into world tiles and reduce HUD dependence.
- Expected impact: 盤面観察だけでリスク判断しやすくなる。
- Risk: 情報量不足で初見理解が遅れる可能性。
- Complexity cost: state count +0, exception rules +1。

### Option B (operators: Spatial historization + Risk reward shift)

- Rune spawn biased to “already corrupted border” and disable score in safe center.
- Expected impact: 危険域での計画投擲を強制し exploratory ratio 上昇見込み。
- Risk: 序盤の学習コスト上昇。
- Complexity cost: state count +0, exception rules +2 (spawn bias / safe-zone no-score)。

### Option C (free-form)

- Introduce one-way gates that reflect pulses once; gate orientation rotates when player passes through.
- Expected impact: パズル性と将来予測性が増し、投擲ルート設計が深化。
- Risk: 可読性低下、初見難化。
- Complexity cost: state count +1 (`gate_orientation`), exception rules +2。

### Adoption Candidate Rationale

Option B を第一候補。既存ルールを壊さず、リスク地帯での得点因果を強化できる。

### Rejection Rationale (current round)

- Option A: 破断の明瞭さを追加実装しないと説明可能性が落ちる。
- Option C: 新規オブジェクト追加で今回スコープを超過。

## 7. Deliverable Index

- [Visual Design](./VISUAL_DESIGN.md)
- [Typography Decision](./TYPOGRAPHY_DECISION.md)
- [Sound Design](./SOUND_DESIGN.md)
- [Third Party Licenses](./THIRD_PARTY_LICENSES.md)
- [Test Report JSON](./logs/test.json)
- [Improvement Report](./logs/improvement_report.md)

## 8. Human Feedback Notes

- ルーン命中後に初めて浄化可能になる因果を、通常パルスと強化パルスの形差で明示する。
- 強化パルスがケーブルに触れた際の広域伝搬を、導線全体の逐次通電として見せる。
- 汚染パネルの拡大は、予兆セルへの侵食表現を追加して少しずつ広がる印象を強める。
- ルーン、ジェネレーター、中枢ノードを別シルエットへ分離して役割誤認を減らす。
- 追加改善: ルーン消費後の残留印章、伝搬先頭の高輝度化、ジェネレーターの時間変化、汚染隣接セルの危険縁を導入する。
- レイアウト改善: 画面を `540x540` の正方形へ変更し、HUD は画面上端中央のスコア数字だけに簡略化する。
- BGM を追加し、プレイ中のみ再生、フォーカス喪失時は停止、復帰時は再開する。

## Game Generation Report: Chain Circuit Vault

## Selected Tags

### Mechanics Tags

- field-connected, rule-friendly_fire, on_released-throw

### Visual Tags

- composition-centered-stage, render-uniform-stroke

### Structure Tags

- structure-irreversible_change

## Test Results

| Metric | Initial | After Improvement |
| :--- | :--- | :--- |
| Exploratory Ratio | 0.00x | N/A |

Note: current bundled test output is `logs/test.json` at `2026-03-14 01:55:18 UTC`, and Phase 7 remained evaluation-only.

## Improvements

### Mechanics Improvement

1. Phase 7 included evaluation report only; no mechanics option was implemented in this document set.

### Visual Improvement

1. Human feedback iteration tightened silhouette separation among core node, rune, and generator.
2. The game was reframed to a `540x540` square stage with a top-center score-only HUD and stronger contamination spread telegraphing.

### Sound Improvement

1. Event SFX differentiate normal throw, rune charge, cable conduction, spread warning, spread confirm, generator break, and damage.
2. BGM was added later as a play-session layer and now runs only during active play, pausing on focus loss and resuming on return.
