extends Node3D

# Modular articulated visual rig. The gameplay CharacterBody3D remains independent.
var body_color := Color("#c52d4a")
var accent_color := Color("#222b36")
var skin_color := Color("#d9a27e")
var style_id := "technician"
var phase := 0.0
var action_name := ""
var action_time := 0.0
var rig_root:Node3D
var torso_joint:Node3D
var head_joint:Node3D
var left_arm_joint:Node3D
var right_arm_joint:Node3D
var left_leg_joint:Node3D
var right_leg_joint:Node3D
var carry_prop:Node3D
var last_parent_rotation:=0.0
var turn_amount:=0.0

func configure(body:Color,accent:Color,skin:Color,style:String="technician") -> void:
	body_color=body; accent_color=accent; skin_color=skin; style_id=style

func _ready() -> void:
	_build_actor()

func play_action(name:String,duration:float=0.45) -> void:
	action_name=name; action_time=duration

func set_carrying_pc(enabled:bool) -> void:
	if carry_prop!=null: carry_prop.visible=enabled
	if enabled: play_action("carry",0.8)

func _process(delta:float) -> void:
	phase += delta
	action_time=maxf(0.0,action_time-delta)
	if action_time<=0.0 and action_name!="carry": action_name=""
	var parent_body:=get_parent()
	var speed:=0.0
	if parent_body is CharacterBody3D: speed=Vector2(parent_body.velocity.x,parent_body.velocity.z).length()
	if parent_body is Node3D:
		var current_rotation:float=(parent_body as Node3D).rotation.y
		var angular_delta:float=angle_difference(last_parent_rotation,current_rotation)
		turn_amount=lerpf(turn_amount,clampf(angular_delta*8.0,-1.0,1.0),minf(1.0,delta*11.0))
		last_parent_rotation=current_rotation
	var walking:=speed>0.15
	var cadence:=8.8 if walking else 2.1
	var swing:=sin(phase*cadence)*(0.54 if walking else 0.035)
	if action_name=="interact":
		swing=0.0
		var reach:=sin(clamp((0.45-action_time)/0.45,0.0,1.0)*PI)*0.72
		right_arm_joint.rotation.x=-reach
		left_arm_joint.rotation.x=0.04
	elif action_name=="talk":
		right_arm_joint.rotation.z=sin(phase*5.2)*0.22-0.16
		left_arm_joint.rotation.z=-sin(phase*4.7)*0.14+0.10
	elif action_name=="carry":
		left_arm_joint.rotation.x=-0.88; right_arm_joint.rotation.x=-0.88
		left_arm_joint.rotation.z=-0.22; right_arm_joint.rotation.z=0.22
	elif action_name=="computer":
		left_arm_joint.rotation=Vector3(-0.78,0,-0.10); right_arm_joint.rotation=Vector3(-0.84,0,0.10)
	elif action_name=="workbench":
		left_arm_joint.rotation=Vector3(-1.02,0,-0.17); right_arm_joint.rotation=Vector3(-0.92,0,0.12)
	else:
		left_arm_joint.rotation=Vector3(swing,0,0.04)
		right_arm_joint.rotation=Vector3(-swing,0,-0.04)
	left_leg_joint.rotation.x=-swing*0.72
	right_leg_joint.rotation.x=swing*0.72
	if torso_joint!=null:
		torso_joint.rotation.z=(sin(phase*cadence)*0.018 if walking else sin(phase*1.7)*0.008)+turn_amount*0.075
		torso_joint.rotation.x=-0.10 if action_name in ["computer","workbench"] else 0.0
	if head_joint!=null: head_joint.rotation.y=(sin(phase*1.35)*0.035 if not walking else 0.0)-turn_amount*0.10
	position.y=sin(phase*cadence)*0.018 if walking else sin(phase*1.8)*0.009

func _build_actor() -> void:
	rig_root=Node3D.new(); rig_root.name="VisualRig"; add_child(rig_root)
	# pelvis / torso hierarchy
	var pelvis:=Node3D.new(); pelvis.name="PelvisJoint"; pelvis.position=Vector3(0,0.84,0); rig_root.add_child(pelvis)
	torso_joint=Node3D.new(); torso_joint.name="TorsoJoint"; torso_joint.position=Vector3(0,0.34,0); pelvis.add_child(torso_joint)
	_add_capsule(torso_joint,"Torso",Vector3(0,0.18,0),0.29,0.70,body_color,Vector3(0,0,0),Vector3(1.0,1.0,0.82))
	_add_box(torso_joint,"JacketPanel",Vector3(0,0.19,-0.255),Vector3(0.48,0.46,0.055),accent_color)
	_add_box(torso_joint,"JacketSideLeft",Vector3(-0.245,0.16,-0.18),Vector3(0.075,0.48,0.13),body_color.darkened(0.12))
	_add_box(torso_joint,"JacketSideRight",Vector3(0.245,0.16,-0.18),Vector3(0.075,0.48,0.13),body_color.darkened(0.12))
	_add_box(torso_joint,"JacketZipper",Vector3(0,0.18,-0.289),Vector3(0.025,0.44,0.014),Color("#b9c4cb"))
	var collar_left:=_add_box(torso_joint,"JacketCollar",Vector3(-0.09,0.43,-0.294),Vector3(0.16,0.14,0.028),body_color.lightened(0.08)); collar_left.rotation_degrees.z=-24
	var collar_right:=_add_box(torso_joint,"JacketCollar",Vector3(0.09,0.43,-0.294),Vector3(0.16,0.14,0.028),body_color.lightened(0.08)); collar_right.rotation_degrees.z=24
	_add_box(torso_joint,"Waist",Vector3(0,-0.18,0),Vector3(0.44,0.18,0.28),accent_color)
	# neck/head
	head_joint=Node3D.new(); head_joint.name="HeadJoint"; head_joint.position=Vector3(0,0.74,0); torso_joint.add_child(head_joint)
	_add_cylinder(head_joint,"Neck",Vector3(0,-0.05,0),0.105,0.17,skin_color)
	_add_sphere(head_joint,"Head",Vector3(0,0.22,0),Vector3(0.25,0.29,0.25),skin_color)
	_build_face(head_joint)
	_build_hair(head_joint)
	# shoulders/arms are real pivots rather than rotating mesh centers.
	left_arm_joint=_make_limb_joint(torso_joint,"LeftShoulder",Vector3(-0.35,0.42,0))
	right_arm_joint=_make_limb_joint(torso_joint,"RightShoulder",Vector3(0.35,0.42,0))
	_build_arm(left_arm_joint,-1.0)
	_build_arm(right_arm_joint,1.0)
	left_leg_joint=_make_limb_joint(pelvis,"LeftHip",Vector3(-0.16,-0.04,0))
	right_leg_joint=_make_limb_joint(pelvis,"RightHip",Vector3(0.16,-0.04,0))
	_build_leg(left_leg_joint,-1.0)
	_build_leg(right_leg_joint,1.0)
	_build_style_accessories()
	_build_carry_prop()

func _build_face(parent:Node3D)->void:
	var eye_mat:=_mat(Color("#15191f"),0.55,0.0)
	for x in [-0.085,0.085]:
		_add_sphere(parent,"EyeWhite",Vector3(x,0.25,-0.230),Vector3(0.052,0.039,0.020),Color("#eef4f6"))
		var eye:=_add_sphere(parent,"Eye",Vector3(x,0.25,-0.249),Vector3(0.024,0.027,0.012),Color("#121820")); eye.material_override=eye_mat
		var brow:=_add_box(parent,"Eyebrow",Vector3(x,0.315,-0.247),Vector3(0.075,0.017,0.012),Color("#29231f")); brow.rotation_degrees.z=-6 if x<0 else 6
	for x in [-0.255,0.255]: _add_sphere(parent,"Ear",Vector3(x,0.22,0),Vector3(0.045,0.072,0.036),skin_color.darkened(0.03))
	_add_box(parent,"Nose",Vector3(0,0.18,-0.247),Vector3(0.035,0.065,0.025),skin_color.darkened(0.08))
	_add_box(parent,"Mouth",Vector3(0,0.10,-0.252),Vector3(0.085,0.018,0.014),Color("#7d4d48"))

func _build_hair(parent:Node3D)->void:
	var hair_color:=Color("#161a20") if style_id!="professional" else Color("#3d332f")
	_add_sphere(parent,"HairCap",Vector3(0,0.36,0.015),Vector3(0.255,0.145,0.258),hair_color)
	if style_id=="gamer":
		for i in range(4):
			var spike:=_add_capsule(parent,"HairSpike",Vector3(-0.12+i*0.08,0.48,-0.03),0.035,0.16,hair_color,Vector3(22,0,-18+i*12),Vector3.ONE)
	elif style_id=="female_casual":
		_add_capsule(parent,"HairLeft",Vector3(-0.21,0.20,0.02),0.075,0.48,hair_color,Vector3(0,0,8),Vector3.ONE)
		_add_capsule(parent,"HairRight",Vector3(0.21,0.20,0.02),0.075,0.48,hair_color,Vector3(0,0,-8),Vector3.ONE)
		_add_capsule(parent,"HairBack",Vector3(0,0.14,0.14),0.15,0.56,hair_color,Vector3.ZERO,Vector3(1.0,1.0,0.70))
	elif style_id=="casual":
		_add_capsule(parent,"CasualFringe",Vector3(-0.08,0.43,-0.11),0.065,0.28,hair_color,Vector3(18,0,-24),Vector3.ONE)

func _make_limb_joint(parent:Node3D,n:String,pos:Vector3)->Node3D:
	var joint:=Node3D.new(); joint.name=n; joint.position=pos; parent.add_child(joint); return joint

func _build_arm(joint:Node3D,side:float)->void:
	_add_capsule(joint,"UpperArm",Vector3(0,-0.24,0),0.085,0.47,body_color,Vector3.ZERO,Vector3.ONE)
	var elbow:=Node3D.new(); elbow.name="Elbow"; elbow.position=Vector3(0,-0.46,0); joint.add_child(elbow)
	_add_capsule(elbow,"Forearm",Vector3(0,-0.19,0),0.075,0.37,accent_color,Vector3.ZERO,Vector3.ONE)
	_add_sphere(elbow,"Hand",Vector3(0,-0.41,-0.01),Vector3(0.09,0.10,0.085),skin_color)

func _build_leg(joint:Node3D,side:float)->void:
	_add_capsule(joint,"Thigh",Vector3(0,-0.26,0),0.11,0.50,accent_color,Vector3.ZERO,Vector3.ONE)
	var knee:=Node3D.new(); knee.name="Knee"; knee.position=Vector3(0,-0.49,0); joint.add_child(knee)
	_add_capsule(knee,"Shin",Vector3(0,-0.20,0),0.095,0.40,accent_color.darkened(0.08),Vector3.ZERO,Vector3.ONE)
	_add_box(knee,"Shoe",Vector3(0,-0.43,-0.08),Vector3(0.22,0.13,0.38),Color("#0d1319"))

func _build_style_accessories()->void:
	if style_id=="technician":
		_add_box(torso_joint,"EmpireBadge",Vector3(0.17,0.26,-0.292),Vector3(0.17,0.075,0.018),Color("#f23a59"))
		_add_box(torso_joint,"UtilityBelt",Vector3(0,-0.15,-0.18),Vector3(0.50,0.09,0.06),Color("#11171e"))
		_add_box(torso_joint,"ToolPouch",Vector3(-0.25,-0.16,-0.16),Vector3(0.16,0.20,0.11),Color("#1b252e"))
		_add_box(torso_joint,"WristTerminal",Vector3(0.39,-0.13,-0.02),Vector3(0.09,0.13,0.12),Color("#36c2e8"))
	elif style_id=="gamer":
		_add_box(torso_joint,"HoodiePocket",Vector3(0,0.0,-0.29),Vector3(0.32,0.13,0.035),accent_color.lightened(0.08))
		_add_capsule(head_joint,"HeadsetBand",Vector3(0,0.33,0.0),0.025,0.52,Color("#111820"),Vector3(0,0,90),Vector3.ONE)
		for x in [-0.255,0.255]: _add_cylinder(head_joint,"HeadsetCup",Vector3(x,0.23,0),0.075,0.06,Color("#202a34"),Vector3(0,0,90))
		for x in [-0.07,0.07]: _add_cylinder(torso_joint,"HoodString",Vector3(x,0.31,-0.305),0.012,0.28,Color("#e6edf1"))
	elif style_id=="professional":
		_add_box(torso_joint,"ShirtFront",Vector3(0,0.20,-0.288),Vector3(0.30,0.42,0.035),Color("#d9e0e5"))
		_add_box(torso_joint,"Tie",Vector3(0,0.22,-0.312),Vector3(0.055,0.34,0.020),Color("#7d273c"))
		var lapel_left:=_add_box(torso_joint,"Lapel",Vector3(-0.12,0.31,-0.315),Vector3(0.16,0.30,0.022),body_color.lightened(0.10)); lapel_left.rotation_degrees.z=-18
		var lapel_right:=_add_box(torso_joint,"Lapel",Vector3(0.12,0.31,-0.315),Vector3(0.16,0.30,0.022),body_color.lightened(0.10)); lapel_right.rotation_degrees.z=18
	elif style_id=="female_casual":
		_add_box(torso_joint,"TopAccent",Vector3(0,0.24,-0.286),Vector3(0.34,0.30,0.035),accent_color.lightened(0.14))
		for x in [-0.257,0.257]: _add_sphere(head_joint,"Earring",Vector3(x,0.15,-0.03),Vector3(0.026,0.040,0.024),Color("#e6b85c"))
	elif style_id=="casual":
		_add_box(torso_joint,"CasualOvershirt",Vector3(0,0.17,-0.290),Vector3(0.36,0.38,0.035),body_color.lightened(0.10))
		_add_box(torso_joint,"CasualPocket",Vector3(-0.12,0.22,-0.316),Vector3(0.12,0.10,0.018),accent_color.lightened(0.14))

func _build_carry_prop()->void:
	carry_prop=Node3D.new(); carry_prop.name="CarryPCProp"; carry_prop.position=Vector3(0,0.88,-0.52); carry_prop.visible=false; rig_root.add_child(carry_prop)
	_add_box(carry_prop,"Case",Vector3.ZERO,Vector3(0.58,0.72,0.46),Color("#151d25"))
	var glass:=_add_box(carry_prop,"Glass",Vector3(0.30,0,0),Vector3(0.025,0.58,0.36),Color(0.13,0.22,0.28,0.45)); var gm:=_mat(Color(0.13,0.22,0.28,0.45),0.12,0.08); gm.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; glass.material_override=gm
	_add_box(carry_prop,"LED",Vector3(0,0.26,-0.24),Vector3(0.32,0.028,0.018),Color("#e63b5c"))

func _add_box(parent:Node3D,n:String,p:Vector3,s:Vector3,c:Color)->MeshInstance3D:
	var node:=MeshInstance3D.new(); node.name=n; node.position=p; var mesh:=BoxMesh.new(); mesh.size=s; node.mesh=mesh; node.material_override=_mat(c,0.48,0.08); parent.add_child(node); return node

func _add_capsule(parent:Node3D,n:String,p:Vector3,r:float,h:float,c:Color,rot:Vector3,scale_value:Vector3)->MeshInstance3D:
	var node:=MeshInstance3D.new(); node.name=n; node.position=p; node.rotation_degrees=rot; node.scale=scale_value
	var mesh:=CapsuleMesh.new(); mesh.radius=r; mesh.height=maxf(h,r*2.05); mesh.radial_segments=16; mesh.rings=6; node.mesh=mesh; node.material_override=_mat(c,0.52,0.04); parent.add_child(node); return node

func _add_cylinder(parent:Node3D,n:String,p:Vector3,r:float,h:float,c:Color,rot:Vector3=Vector3.ZERO)->MeshInstance3D:
	var node:=MeshInstance3D.new(); node.name=n; node.position=p; node.rotation_degrees=rot; var mesh:=CylinderMesh.new(); mesh.top_radius=r; mesh.bottom_radius=r; mesh.height=h; mesh.radial_segments=18; node.mesh=mesh; node.material_override=_mat(c,0.50,0.05); parent.add_child(node); return node

func _add_sphere(parent:Node3D,n:String,p:Vector3,scale_value:Vector3,c:Color)->MeshInstance3D:
	var node:=MeshInstance3D.new(); node.name=n; node.position=p; node.scale=scale_value/0.25; var mesh:=SphereMesh.new(); mesh.radius=0.25; mesh.height=0.50; mesh.radial_segments=20; mesh.rings=10; node.mesh=mesh; node.material_override=_mat(c,0.58,0.0); parent.add_child(node); return node

func _mat(c:Color,rough:float,metal:float)->StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=c; m.roughness=rough; m.metallic=metal; return m
