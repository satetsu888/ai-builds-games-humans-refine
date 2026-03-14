extends RefCounted

const MetricsTracker = preload("res://metrics_tracker.gd")

var score := 0
var elapsed := 0.0
var game_over := false
var game_over_reason := ""
var difficulty_level := 1
var active_entities: Array = []

var entity_type_counts: Dictionary = {}
var behavior_event_counts: Dictionary = {}
var max_single_type_ratio := 0.0
var avg_active_entities_30s := 0.0
var untelegraphed_fail_count := 0
var _active_entity_sample_sum := 0.0
var _active_entity_sample_frames := 0

func reset() -> void:
	score = 0
	elapsed = 0.0
	game_over = false
	game_over_reason = ""
	difficulty_level = 1
	active_entities.clear()
	var m := MetricsTracker.reset_metric_trackers(
		{"rune": true, "corruption": true, "pulse": true},
		["throw", "score", "friendly_fire", "spread", "risky_score", "enhanced_throw", "purify"]
	)
	entity_type_counts = m["entity_type_counts"]
	behavior_event_counts = m["behavior_event_counts"]
	max_single_type_ratio = 0.0
	avg_active_entities_30s = 0.0
	untelegraphed_fail_count = 0
	_active_entity_sample_sum = 0.0
	_active_entity_sample_frames = 0

func tick(delta: float) -> void:
	if game_over:
		return
	elapsed += delta
	difficulty_level = 1 + int(floor(elapsed / 60.0))

func add_score(points: int, risky: bool) -> void:
	if points <= 0:
		return
	score += points
	MetricsTracker.inc_behavior_event(behavior_event_counts, "score")
	if risky:
		MetricsTracker.inc_behavior_event(behavior_event_counts, "risky_score")

func end_game(reason: String) -> void:
	game_over = true
	game_over_reason = reason

func update_entity_telemetry(entity_snapshots: Array) -> void:
	active_entities = entity_snapshots.duplicate(true)
	var update := MetricsTracker.update_test_metrics(
		elapsed,
		active_entities,
		_active_entity_sample_sum,
		_active_entity_sample_frames,
		max_single_type_ratio
	)
	max_single_type_ratio = float(update["max_single_type_ratio"])
	_active_entity_sample_sum = float(update["active_entity_sample_sum"])
	_active_entity_sample_frames = int(update["active_entity_sample_frames"])
	avg_active_entities_30s = float(update["avg_active_entities_30s"])

func register_spawn(entity_type: String) -> void:
	MetricsTracker.record_spawned_entity(entity_type_counts, entity_type)

func register_event(event_name: String) -> void:
	MetricsTracker.inc_behavior_event(behavior_event_counts, event_name)
