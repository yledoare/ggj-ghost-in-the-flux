extends Control


func _on_bouton_jouer_pressed() -> void:
	get_tree().change_scene_to_file("res://intro.tscn")


func _on_bouton_credits_pressed() -> void:
	$fondCredits.visible=true


func _on_bouton_retour_pressed() -> void:
	$fondCredits.visible=false
