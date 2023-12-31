extends Node

# TODO: Figure this out some other way
var enabled := true
const APP_ID := 2716690

var stats_received := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if enabled:
		OS.set_environment("SteamAppId", str(APP_ID))
		OS.set_environment("SteamGameId", str(APP_ID))
		var res := Steam.steamInit()
		print("Steam init: %s" % res)
		print("Steam running: %s" % Steam.isSteamRunning())
		if res.status != Steam.RESULT_OK:
			enabled = false
	if not enabled:
		set_process(false)
		set_process_input(false)
		return
	Steam.current_stats_received.connect(_stats_received)
	Steam.requestCurrentStats()

func _stats_received(game: int, result: int, user: int) -> void:
	if stats_received:
		return
	print("Steam stats received! (result = %d, game = %d, user = %d)" % [result, game, user])
	stats_received = true
	SteamStats.update_campaign_stats()

func store_stats() -> void:
	if not stats_received:
		Steam.requestCurrentStats()
		return
	print("Storing steam stats")
	Steam.storeStats()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		store_stats()
		Steam.steamShutdown()


func _process(_dt: float) -> void:
	Steam.run_callbacks()

class UploadResult:
	var id: int
	var success: bool
	func _init(id_: int, success_: bool) -> void:
		id = id_
		success = success_

var uploading := false

func upload_ugc_item(id: int, title: String, description: String, dir: String, preview_file: String) -> UploadResult:
	if uploading:
		return UploadResult.new(id, false)
	UploadingToWorkshop.start()
	dir = ProjectSettings.globalize_path(dir)
	preview_file = ProjectSettings.globalize_path(preview_file)
	uploading = true
	if id == -1:
		id = await _create_item_id()
	var success := false
	if id != -1:
		success = await _upload_item(id, title, description, dir, preview_file)
	uploading = false
	UploadingToWorkshop.stop()
	return UploadResult.new(id, success)

func _create_item_id() -> int:
	Steam.createItem(SteamManager.APP_ID, Steam.WORKSHOP_FILE_TYPE_COMMUNITY)
	var ret: Array = await Steam.item_created
	var res: Steam.Result = ret[0]
	var id: int = ret[1]
	var needs_tos: bool = ret[2]
	if res != Steam.RESULT_OK:
		push_error("Failed to create item: %s" % res)
		return -1
	print("Successfully created item %d" % id)
	if needs_tos:
		Steam.activateGameOverlayToWebPage("steam://url/CommunityFilePage/%d" % id)
	return id

func _upload_item(id: int, title: String, description: String, dir: String, preview_file: String) -> bool:
	var update_id := Steam.startItemUpdate(SteamManager.APP_ID, id)
	Steam.setItemContent(update_id, dir)
	Steam.setItemTitle(update_id, title)
	Steam.setItemDescription(update_id, description)
	Steam.setItemPreview(update_id, preview_file)
	Steam.submitItemUpdate(update_id, Time.get_datetime_string_from_system(true, true))
	UploadingToWorkshop.update_handle = update_id
	var ret: Array = await Steam.item_updated
	var res: Steam.Result = ret[0]
	var needs_tos: bool = ret[1]
	if res != Steam.RESULT_OK:
		push_error("Failed to upload item: %s" % res)
		return false
	if needs_tos:
		Steam.activateGameOverlayToWebPage("steam://url/CommunityFilePage/%d" % id)
	print("Successfuly updated item %d" % id)
	return true
