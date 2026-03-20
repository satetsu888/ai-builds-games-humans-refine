extends SceneTree

const TEST_SECONDS := 30.0
const DELTA := 1.0 / 60.0
const KPI_EXPLORATION_RATIO_MIN := 1.0
const STRICT_GAMEPLAY_ASSERTS := false

const TEST_JSON_PATH := "res://logs/test.json"
const IMPROVEMENT_REPORT_PATH := "res://logs/improvement_report.md"
const IMPROVEMENT_HISTORY_PATH := "res://logs/improvement_history.json"
const IMPROVEMENT_HISTORY_LIMIT := 3

## Periodic cycle periods (in frames) to test fixed-rhythm resistance.
const PERIODIC_CYCLE_PERIODS := [30, 60, 90, 120, 180]
## Duty ratios to test for each periodic cycle (fraction of cycle spent holding).
const PERIODIC_DUTY_RATIOS := [0.25, 0.5, 0.75]

var _failures := 0

func _init() -> void:
	var scene := load("res://main.tscn") as PackedScene
	if scene == null:
		_fail("main.tscn not found")
		_finish()
		return

	var game: Node = scene.instantiate()
	if game == null:
		_fail("failed to instantiate main.tscn")
		_finish()
		return

	root.add_child(game)
	if not game.has_method("enable_test_mode") or not game.has_method("step_for_test"):
		_fail("test hooks are missing on main.gd")
		_finish()
		return
	if not game.has_method("set_wave_for_test"):
		_fail("set_wave_for_test hook is missing on main.gd")
		_finish()
		return

	game.enable_test_mode(true)

	var use_dict := game.has_method("step_for_test_dict")
	var channels := _get_input_channel_names(game)

	# --- monotonous tests ---
	var mono_results := _run_monotonous_tests(game, use_dict, channels)
	var mono_max := 0
	for key in mono_results:
		var s := int(mono_results[key]["score"])
		if s > mono_max:
			mono_max = s

	# --- periodic tests ---
	var periodic_results := _run_periodic_tests(game, use_dict, channels)
	var periodic_max := 0
	for key in periodic_results:
		var s := int(periodic_results[key]["score"])
		if s > periodic_max:
			periodic_max = s

	# --- exploratory tests ---
	var explore_results := _run_exploratory_tests(game, use_dict, channels)
	var best: Dictionary = explore_results["best"]
	var all_scores: Array = explore_results["all_scores"]

	# --- compute metrics ---
	var explore_best_score := int(best["score"])
	var exploratory_ratio := _calc_ratio(explore_best_score, mono_max)
	var periodic_resistance := _calc_ratio(explore_best_score, periodic_max)
	var score_stddev := _calc_stddev(all_scores)
	var score_mean := _calc_mean(all_scores)
	var score_cv := score_stddev / maxf(1.0, score_mean)

	var report := {
		"version": "1.1",
		"timestamp_utc": Time.get_datetime_string_from_system(true, true),
		"monotonous": {
			"cases": mono_results,
			"max_score": mono_max,
		},
		"periodic": {
			"cases": periodic_results,
			"max_score": periodic_max,
		},
		"exploratory": {
			"best": best,
			"best_seed": int(explore_results["best_seed"]),
			"best_variant": int(explore_results["best_variant"]),
			"all_scores": all_scores,
			"score_mean": snappedf(score_mean, 0.01),
			"score_stddev": snappedf(score_stddev, 0.01),
			"score_cv": snappedf(score_cv, 0.001),
		},
		"exploratory_ratio": exploratory_ratio,
		"periodic_resistance": periodic_resistance,
		"telemetry": {
			"death_analysis": {
				"game_over": bool(best.get("game_over", false)),
				"elapsed": float(best.get("elapsed", 0.0)),
				"untelegraphed_fail_count": int(best.get("untelegraphed_fail_count", 0)),
			},
			"spawn_analysis": {
				"entity_type_counts": best.get("entity_type_counts", {}).duplicate(true),
				"max_single_type_ratio": float(best.get("max_single_type_ratio", 0.0)),
				"avg_active_entities_30s": float(best.get("avg_active_entities_30s", 0.0)),
			},
			"scoring_analysis": {
				"score": explore_best_score,
			},
			"input_analysis": {
				"test_input_usage": best.get("test_input_usage", {}).duplicate(true),
			},
		},
	}

	if not _validate_report_schema(report):
		_fail("test report schema validation failed")
	else:
		_write_json(TEST_JSON_PATH, report)
		_update_improvement_reports(report)

	if STRICT_GAMEPLAY_ASSERTS:
		_assert_true(exploratory_ratio > KPI_EXPLORATION_RATIO_MIN, "exploration ratio should exceed threshold")

	print("exploratory_ratio=", snappedf(exploratory_ratio, 0.01))
	print("periodic_resistance=", snappedf(periodic_resistance, 0.01))
	print("score_cv=", snappedf(score_cv, 0.001))
	print("tests completed")
	_finish()

# ── monotonous tests ──

func _run_monotonous_tests(game: Node, use_dict: bool, channels: Array[String]) -> Dictionary:
	var custom_policies: Array = []
	if game.has_method("get_monotonous_policies"):
		custom_policies = game.get_monotonous_policies()
	if custom_policies.size() > 0:
		var results := {}
		for entry in custom_policies:
			var pname: String = entry["name"]
			var policy: Callable = entry["policy"]
			results[pname] = _result_summary(_simulate(game, 1001 + results.size(), policy, use_dict, channels))
		return results
	var primary := channels[0]
	return {
		"no_input": _result_summary(_simulate(game, 1001, func(_f): return _empty_input(channels), use_dict, channels)),
		"hold_primary": _result_summary(_simulate(game, 1002, func(_f): return _input_with(channels, primary, true), use_dict, channels)),
		"pulse_primary": _result_summary(_simulate(game, 1003, func(f): return _input_with(channels, primary, (f % 6) < 3), use_dict, channels)),
	}

# ── periodic tests ──

func _run_periodic_tests(game: Node, use_dict: bool, channels: Array[String]) -> Dictionary:
	var custom_policies: Array = []
	if game.has_method("get_periodic_policies"):
		custom_policies = game.get_periodic_policies()
	if custom_policies.size() > 0:
		var results := {}
		for entry in custom_policies:
			var pname: String = entry["name"]
			var policy: Callable = entry["policy"]
			results[pname] = _result_summary(_simulate(game, 3001 + results.size(), policy, use_dict, channels))
		return results
	var primary := channels[0]
	var results := {}
	var seed_counter := 3001
	for period in PERIODIC_CYCLE_PERIODS:
		for duty in PERIODIC_DUTY_RATIOS:
			var on_frames := int(float(period) * duty)
			var p := period  # capture for lambda
			var on := on_frames  # capture for lambda
			var policy := func(f: int) -> Dictionary:
				return _input_with(channels, primary, (f % p) < on)
			var label := "period_%d_duty_%d" % [period, int(duty * 100)]
			results[label] = _result_summary(_simulate(game, seed_counter, policy, use_dict, channels))
			seed_counter += 1
	return results

# ── exploratory tests ──

func _run_exploratory_tests(game: Node, use_dict: bool, channels: Array[String]) -> Dictionary:
	var custom_policies: Array = []
	if game.has_method("get_exploration_policies"):
		custom_policies = game.get_exploration_policies()
	var best: Dictionary = {"score": -1}
	var best_seed := -1
	var best_variant := -1
	var all_scores: Array = []
	if custom_policies.size() > 0:
		for vi in range(custom_policies.size()):
			var policy: Callable = custom_policies[vi]["policy"]
			for i in range(8):
				var s := 2000 + vi * 100 + i
				var result: Dictionary = _simulate(game, s, policy, use_dict, channels)
				var sc := int(result["score"])
				all_scores.append(sc)
				if sc > int(best["score"]):
					best = result
					best_seed = s
					best_variant = vi
	else:
		for variant in range(4):
			for i in range(8):
				var s := 2000 + variant * 100 + i
				var result: Dictionary = _simulate(game, s, func(frame: int): return _exploration_input_variant(frame, variant, channels), use_dict, channels)
				var sc := int(result["score"])
				all_scores.append(sc)
				if sc > int(best["score"]):
					best = result
					best_seed = s
					best_variant = variant
	return {
		"best": _result_summary(best),
		"best_seed": best_seed,
		"best_variant": best_variant,
		"all_scores": all_scores,
	}

func _exploration_input_variant(frame: int, variant: int, channels: Array[String]) -> Dictionary:
	var cycle := (frame + variant * 23) % 120
	var out := _empty_input(channels)
	for i in range(channels.size()):
		var channel := channels[i]
		var shifted := (cycle + i * 17 + variant * 11) % 120
		out[channel] = shifted < 24 or (shifted >= 72 and shifted < 90)
	if channels.size() >= 2:
		var c0 := channels[0]
		var c1 := channels[1]
		if bool(out[c0]) and bool(out[c1]):
			out[c1] = false
	return out

# ── simulation ──

func _simulate(game: Node, test_seed: int, policy: Callable, use_dict: bool, channels: Array[String]) -> Dictionary:
	game.force_reset_for_test(test_seed)
	var frames := int(TEST_SECONDS / DELTA)
	var channel_counts := {}
	for channel in channels:
		channel_counts[channel] = 0
	var actual_frames := 0
	for i in range(frames):
		var input := _normalize_input(policy.call(i), channels)
		if use_dict:
			game.step_for_test_dict(DELTA, input)
		else:
			var action_a := bool(input.get("action_a", false))
			var action_b := bool(input.get("action_b", false))
			var action_c := bool(input.get("action_c", false))
			game.step_for_test(DELTA, action_a, action_b, action_c)
		actual_frames += 1
		for ch_name in channels:
			var val: Variant = input.get(ch_name, false)
			if typeof(val) == TYPE_BOOL and val:
				channel_counts[ch_name] = int(channel_counts[ch_name]) + 1
			elif typeof(val) != TYPE_BOOL:
				channel_counts[ch_name] = int(channel_counts[ch_name]) + 1
		var mid: Dictionary = game.get_metrics()
		if bool(mid.get("game_over", false)):
			break
	var out: Dictionary = game.get_metrics()
	var usage := {"frames": actual_frames}
	var denom := maxf(1.0, float(actual_frames))
	for ch_name in channel_counts:
		usage[ch_name + "_ratio"] = float(channel_counts[ch_name]) / denom
	out["test_input_usage"] = usage
	return out

# ── helpers ──

func _get_input_channel_names(game: Node) -> Array[String]:
	var fallback: Array[String] = ["action_a", "action_b", "action_c"]
	if not game.has_method("get_test_input_channels"):
		return fallback
	var raw: Variant = game.get_test_input_channels()
	if typeof(raw) != TYPE_ARRAY:
		return fallback
	var out: Array[String] = []
	for entry in raw:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var name := str(entry.get("name", "")).strip_edges()
		if name == "":
			continue
		out.append(name)
	if out.is_empty():
		return fallback
	return out

func _empty_input(channels: Array[String]) -> Dictionary:
	var out := {}
	for channel in channels:
		out[channel] = false
	return out

func _input_with(channels: Array[String], channel: String, state: bool) -> Dictionary:
	var out := _empty_input(channels)
	if out.has(channel):
		out[channel] = state
	return out

func _normalize_input(raw_input: Variant, channels: Array[String]) -> Dictionary:
	var out := _empty_input(channels)
	if typeof(raw_input) != TYPE_DICTIONARY:
		return out
	var inp := raw_input as Dictionary
	for channel in channels:
		if inp.has(channel):
			out[channel] = inp[channel]
	return out

func _result_summary(result: Dictionary) -> Dictionary:
	var entity_type_counts: Dictionary = result.get("entity_type_counts", result.get("enemy_type_counts", {})).duplicate(true)
	var avg_active_entities_30s := float(result.get("avg_active_entities_30s", result.get("avg_active_enemies_30s", 0.0)))
	var untelegraphed_fail_count := int(result.get("untelegraphed_fail_count", result.get("untelegraphed_hit_count", 0)))
	return {
		"score": int(result.get("score", 0)),
		"game_over": bool(result.get("game_over", false)),
		"elapsed": float(result.get("elapsed", 0.0)),
		"entity_type_counts": entity_type_counts,
		"max_single_type_ratio": float(result.get("max_single_type_ratio", 0.0)),
		"avg_active_entities_30s": avg_active_entities_30s,
		"untelegraphed_fail_count": untelegraphed_fail_count,
		"test_input_usage": result.get("test_input_usage", {}).duplicate(true),
	}

# ── statistics ──

func _calc_ratio(explore_score: int, mono_max: int) -> float:
	if mono_max > 0:
		return float(explore_score) / float(mono_max)
	if explore_score > 0:
		return 9.9
	return 0.0

func _calc_mean(scores: Array) -> float:
	if scores.is_empty():
		return 0.0
	var total := 0.0
	for s in scores:
		total += float(s)
	return total / float(scores.size())

func _calc_stddev(scores: Array) -> float:
	if scores.size() < 2:
		return 0.0
	var mean := _calc_mean(scores)
	var sum_sq := 0.0
	for s in scores:
		var diff := float(s) - mean
		sum_sq += diff * diff
	return sqrt(sum_sq / float(scores.size()))

# ── validation & reporting ──

func _validate_report_schema(report: Dictionary) -> bool:
	var required := [
		"monotonous.max_score",
		"periodic.max_score",
		"exploratory.best.score",
		"exploratory.score_stddev",
		"exploratory_ratio",
		"periodic_resistance",
		"telemetry.death_analysis",
		"telemetry.spawn_analysis",
		"telemetry.scoring_analysis",
		"telemetry.input_analysis",
	]
	for path in required:
		if not _has_nested(report, path):
			_fail("missing required report field: %s" % path)
			return false
	return true

func _has_nested(root_dict: Dictionary, path: String) -> bool:
	var node: Variant = root_dict
	for key in path.split("."):
		if typeof(node) != TYPE_DICTIONARY:
			return false
		var d := node as Dictionary
		if not d.has(key):
			return false
		node = d[key]
	return true

func _write_json(path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("failed to open %s for write" % path)
		return
	file.store_string(JSON.stringify(payload, "\t", false))

func _update_improvement_reports(report: Dictionary) -> void:
	var history := _load_improvement_history()
	var snapshot := {
		"timestamp_utc": str(report.get("timestamp_utc", "")),
		"exploratory_ratio": float(report.get("exploratory_ratio", 0.0)),
		"periodic_resistance": float(report.get("periodic_resistance", 0.0)),
		"score_cv": float(report.get("exploratory", {}).get("score_cv", 0.0)),
		"monotonous_max_score": int(report.get("monotonous", {}).get("max_score", 0)),
		"periodic_max_score": int(report.get("periodic", {}).get("max_score", 0)),
		"exploratory_best_score": int(report.get("exploratory", {}).get("best", {}).get("score", 0)),
		"status": _status_from_metrics(report),
	}
	history.append(snapshot)
	while history.size() > IMPROVEMENT_HISTORY_LIMIT:
		history.remove_at(0)
	_write_json(IMPROVEMENT_HISTORY_PATH, {"history": history})

	var lines: Array[String] = []
	lines.append("# Improvement Report")
	lines.append("")
	lines.append("| Run | Timestamp (UTC) | Expl. Ratio | Periodic Resist. | Score CV | Mono Max | Periodic Max | Expl. Best | Status |")
	lines.append("| :-- | :-------------- | ----------: | ---------------: | -------: | -------: | -----------: | ---------: | :----- |")
	for i in range(history.size()):
		var h := history[i] as Dictionary
		lines.append("| %d | %s | %.2f | %.2f | %.3f | %d | %d | %d | %s |" % [
			i + 1,
			str(h.get("timestamp_utc", "-")),
			float(h.get("exploratory_ratio", 0.0)),
			float(h.get("periodic_resistance", 0.0)),
			float(h.get("score_cv", 0.0)),
			int(h.get("monotonous_max_score", 0)),
			int(h.get("periodic_max_score", 0)),
			int(h.get("exploratory_best_score", 0)),
			str(h.get("status", "-")),
		])
	var out := FileAccess.open(IMPROVEMENT_REPORT_PATH, FileAccess.WRITE)
	if out == null:
		_fail("failed to write %s" % IMPROVEMENT_REPORT_PATH)
		return
	out.store_string("\n".join(lines) + "\n")

func _load_improvement_history() -> Array:
	if not FileAccess.file_exists(IMPROVEMENT_HISTORY_PATH):
		return []
	var file := FileAccess.open(IMPROVEMENT_HISTORY_PATH, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var data := parsed as Dictionary
	var history: Variant = data.get("history", [])
	return history if typeof(history) == TYPE_ARRAY else []

func _status_from_metrics(report: Dictionary) -> String:
	var expl_ratio := float(report.get("exploratory_ratio", 0.0))
	var periodic_res := float(report.get("periodic_resistance", 0.0))
	var cv := float(report.get("exploratory", {}).get("score_cv", 0.0))
	if expl_ratio <= 1.0 or periodic_res <= 1.5:
		return "fail"
	if expl_ratio <= 1.5 or periodic_res <= 3.0 or cv < 0.1:
		return "needs_improvement"
	if cv < 0.3:
		return "needs_improvement"
	return "pass"

func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)

func _fail(message: String) -> void:
	_failures += 1
	printerr("assert failed: ", message)

func _finish() -> void:
	if _failures > 0:
		printerr("tests failed: ", _failures)
		quit(1)
		return
	quit(0)
