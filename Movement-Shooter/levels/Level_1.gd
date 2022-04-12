extends Spatial

var player = preload("res://mobs/Player.tscn")


func _ready():
	print("signals connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("network_peer_connected", self, "_player_joined")
	Globals.connect("instance_player", self, "_instance_player")
	
	
func _player_joined(id):
	print(str(id)+" connected")
	print(str(get_tree().get_network_connected_peers())+" are in the game")
	_instance_player(id)
	pass
	
func _player_disconnected(id):
	if has_node(str(id)):
		get_node(str(id)).queue_free()
	pass
	
func _instance_player(id):
	print("creating player " +str(id))
	var p = player.instance()
	p.set_network_master(id)
	p.name = str(id)
	NetNodes.add_child(p)
	p.transform.origin.y +=10
