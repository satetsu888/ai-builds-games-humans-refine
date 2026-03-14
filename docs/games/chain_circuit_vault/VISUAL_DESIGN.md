# Visual Design: Chain Circuit Vault

## 1. Concept

中央に凝縮した抽象盤面で、均一線幅の記号が「安全回路」と「汚染拡散」の対立を示す。神秘的なルーン印章が工業的な汚染炉に対抗し、信号パルスが強化されて初めて浄化電流へ変わる。

## 2. Palette (7 colors)

- `#0f1726` Background field
- `#2f4d68` Grid/stroke system
- `#e7fcff` Protagonist core
- `#f3c969` Reward rune
- `#872634` Threat corruption
- `#ff8e42` Generator core accent
- `#7fffd1` Enhanced pulse / charged cable accent

## 3. Render Specs

- 540x540 固定。盤面は中央ステージ配置。
- すべて線幅 3-6px の均一ストロークで描画。
- ケーブルは連結線+節点で field-connected を可視化。
- ルーンは二重リングと刻印線、ジェネレーターは六角炉心と外向きノッチでシルエット分離。
- パルスは通常時「白い信号枠」、強化時「青緑の十字芯+外周光」に変化させる。
- 汚染拡散予兆は汚染セルと候補セルの境界が赤熱し、候補セル側の侵食縁がにじむ形で描く。
- ルーン命中後は短時間だけ残留印章を残し、「ここで強化が起きた」痕跡を盤面に刻む。
- 強化ケーブル伝搬は先頭セルを高輝度、通過セルを減衰残光として描き分ける。
- ジェネレーターは外周リングと排気ノッチを微回転させ、汚染を吐き出す炉心として見せる。

## 4. Feedback Mapping

- Score: 強化パルス十字発光 + 浄化セルの白緑フラッシュ
- Damage/Friendly fire: 非強化パルスがケーブルで停止し、導線発光が途切れる
- Near miss: 汚染隣接ルーン命中時に印章リングが白く収束発光
- State change: ルーン命中でパルス外形が変化、ケーブル接触で逐次通電、汚染拡散時に侵食予兆が確定赤化
- State memory: ルーン消費後の残留印章、汚染隣接セルの赤い縁で直前の出来事と次の危険を保持

## 5. Anti-Generic Rules

- アイコンや絵文字型記号は使わず、円・線・矩形のみで役割分離。
- UIテキストに依存せず、危険は盤面色変化で伝達。
- 画面中央以外は情報密度を下げ、視線を中枢へ戻す。
- 円形カテゴリを乱用しない。中枢=純円、ルーン=印章リング、ジェネレーター=角張り炉心、で意味を固定する。
- HUD は上端中央のスコア数字のみ。操作説明や状態説明は盤面内の変化で伝える。

## 6. Layer Composition

- Background: 深紺単層
- Play field: グリッド + 汚染タイル + ルーン
- Foreground: ケーブル、プレイヤー中枢、投擲パルス
- Typography: 上端中央の単独スコア数字のみ。等幅で硬質な字面を使い、回路記号群の一部として扱う。

## 7. AI-Generated Look Suppression Rules

### 7.1 Visual Hierarchy Rules

- Protagonist: 中央の白い中枢ノード
- Threat: 赤固定化する汚染タイル
- Reward: 金色ルーン
- 2-second recognition check: 初見2秒で「白=自機」「赤=危険」「金=得点対象」を判別可能

### 7.2 Limits on Familiar Template Symbols

- Adopted familiar elements (max 2): グリッド背景、円形プレイヤー
- Replaced unique element: 一般的な敵キャラを廃し、行動履歴ケーブルを危険対象へ転化

### 7.3 UI-Independent Feedback

| Event | Non-UI visual response | Intensity (Low/Med/High) |
| :---- | :--------------------- | :----------------------- |
| Score | 青緑の強化十字と浄化フラッシュ | Med |
| Damage | 非強化パルス停止 + 導線の断絶感 | High |
| Near miss | 汚染隣接命中で印章リングが白く収束発光 | Med |
| Spread warning | 汚染側から候補セルへ侵食線がにじむ | Med |

### 7.4 Composition and Gaze Guidance

- Initial focal point: 盤面中央の中枢ノード
- Visual flow: 中枢→ケーブル→ルーン→汚染境界
- Anti-center-clutter implementation: HUD は画面上端中央のスコア数字のみに抑え、イベント可視化は中央盤面内へ集約する
