extends Node3D

var body_color := Color("#c52d4a")
var accent_color := Color("#222b36")
var skin_color := Color("#d9a27e")
var phase := 0.0
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D
var left_leg: MeshInstance3D
var right_leg: MeshInstance3D

func configure(body:Color,accent:Color,skin:Color) -> void:
	body_color=body; accent_color=accent; skin_color=skin

func _ready() -> void:
	_build_actor()

func _process(delta:float) -> void:
	phase += delta
	var parent_body := get_parent()
	var speed := 0.0
	if parent_body is CharacterBody3D:
		speed = Vector2(parent_body.velocity.x,parent_body.velocity.z).length()
	var swing := sin(phase * (8.5 if speed>0.15 else 2.0)) * (0.48 if speed>0.15 else 0.04)
	if left_arm: left_arm.rotation.x=swing
	if right_arm: right_arm.rotation.x=-swing
	if left_leg: left_leg.rotation.x=-swing*0.7
	if right_leg: right_leg.rotation.x=swing*0.7
	position.y = sin(phase*(8.5 if speed>0.15 else 2.0))*0.025 if speed>0.15 else sin(phase*2.0)*0.01

func _build_actor() -> void:
	# Commercial-style readable low-poly silhouette. Replaceable later by imported rig without changing gameplay body.
	_add_part("Torso",Vector3(0,1.18,0),Vector3(0.58,0.72,0.34),body_color)
	_add_part("Jacket",Vector3(0,1.25,-0.19),Vector3(0.62,0.48,0.08),accent_color)
	var neck:=_add_cylinder("Neck",Vector3(0,1.63,0),0.12,0.18,skin_color)
	var head:=MeshInstance3D.new(); head.name="Head"; var sph:=SphereMesh.new(); sph.radius=0.25; sph.height=0.5; head.mesh=sph; head.position=Vector3(0,1.85,0); head.material_override=_mat(skin_color,0.58,0.0); add_child(head)
	# Hair cap.
	var hair:=MeshInstance3D.new(); var hs:=SphereMesh.new(); hs.radius=0.255; hs.height=0.3; hair.mesh=hs; hair.position=Vector3(0,1.98,-0.015); hair.scale=Vector3(1.02,0.55,1.02); hair.material_override=_mat(Color("#17191f"),0.7,0.0); add_child(hair)
	left_arm=_add_part("LeftArm",Vector3(-0.39,1.22,0),Vector3(0.18,0.70,0.18),body_color); left_arm.position.y=1.22
	right_arm=_add_part("RightArm",Vector3(0.39,1.22,0),Vector3(0.18,0.70,0.18),body_color); right_arm.position.y=1.22
	_add_part("LeftHand",Vector3(-0.39,0.84,0),Vector3(0.19,0.19,0.19),skin_color)
	_add_part("RightHand",Vector3(0.39,0.84,0),Vector3(0.19,0.19,0.19),skin_color)
	left_leg=_add_part("LeftLeg",Vector3(-0.17,0.48,0),Vector3(0.22,0.72,0.25),accent_color)
	right_leg=_add_part("RightLeg",Vector3(0.17,0.48,0),Vector3(0.22,0.72,0.25),accent_color)
	_add_part("LeftShoe",Vector3(-0.17,0.12,-0.06),Vector3(0.25,0.16,0.38),Color("#10151b"))
	_add_part("RightShoe",Vector3(0.17,0.12,-0.06),Vector3(0.25,0.16,0.38),Color("#10151b"))
	# Chest accent / shop badge.
	var badge:=_add_part("Badge",Vector3(0.18,1.35,-0.23),Vector3(0.18,0.08,0.03),Color("#f23a57"))

func _add_part(n:String,p:Vector3,s:Vector3,c:Color) -> MeshInstance3D:
	var node:=MeshInstance3D.new(); node.name=n; node.position=p
	var box:=BoxMesh.new(); box.size=s; node.mesh=box; node.material_override=_mat(c,0.52,0.05); add_child(node); return node

func _add_cylinder(n:String,p:Vector3,r:float,h:float,c:Color) -> MeshInstance3D:
	var node:=MeshInstance3D.new(); node.name=n; node.position=p
	var mesh:=CylinderMesh.new(); mesh.top_radius=r; mesh.bottom_radius=r; mesh.height=h; node.mesh=mesh; node.material_override=_mat(c,0.55,0.0); add_child(node); return node

func _mat(c:Color,rough:float,metal:float) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=c; m.roughness=rough; m.metallic=metal; return m
