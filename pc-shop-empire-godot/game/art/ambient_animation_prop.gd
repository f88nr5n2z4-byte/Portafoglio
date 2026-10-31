extends Node3D

var mode:="fan"
var accent:=Color("#38bfe7")
var rotor:Node3D
var scan_bar:MeshInstance3D
var content_root:Node3D
var phase:=0.0

func setup_fan(color:Color,radius:float=0.18)->void:
	mode="fan"; accent=color
	rotor=Node3D.new(); rotor.name="FanRotor"; add_child(rotor)
	var rim:=MeshInstance3D.new(); rim.name="FanRim"; var torus:=TorusMesh.new(); torus.inner_radius=radius*0.82; torus.outer_radius=radius; torus.rings=24; torus.ring_segments=12; rim.mesh=torus; rim.material_override=_mat(Color("#151c24"),0.32,0.42); add_child(rim)
	var hub:=MeshInstance3D.new(); var hub_mesh:=CylinderMesh.new(); hub_mesh.top_radius=radius*0.22; hub_mesh.bottom_radius=radius*0.22; hub_mesh.height=0.04; hub_mesh.radial_segments=20; hub.mesh=hub_mesh; hub.rotation_degrees.x=90; hub.material_override=_emissive(Color("#111820"),accent,1.45); rotor.add_child(hub)
	for i in range(6):
		var angle:=float(i)*60.0
		var blade:=MeshInstance3D.new(); blade.name="Blade"
		var mesh:=BoxMesh.new(); mesh.size=Vector3(radius*0.12,radius*0.78,0.025); blade.mesh=mesh; blade.position=Vector3(sin(deg_to_rad(angle))*radius*0.34,cos(deg_to_rad(angle))*radius*0.34,0.0); blade.rotation_degrees.z=-angle+18.0; blade.material_override=_mat(Color("#2b3540"),0.38,0.24); rotor.add_child(blade)

func setup_screen(color:Color,size_value:Vector2=Vector2(1.0,0.58))->void:
	mode="screen"; accent=color
	content_root=Node3D.new(); content_root.name="AnimatedScreenContent"; add_child(content_root)
	var bg:=_box("ContentBG",Vector3.ZERO,Vector3(size_value.x,size_value.y,0.008),_emissive(Color("#071018"),accent.darkened(0.55),0.65)); content_root.add_child(bg)
	for i in range(3):
		var card:=_box("UIBlock",Vector3(-size_value.x*0.22+i*size_value.x*0.22,0.05-i*0.055,0.008),Vector3(size_value.x*0.16,size_value.y*(0.34-0.04*i),0.006),_emissive(Color("#09131c"),accent.darkened(0.12+0.1*i),0.55)); content_root.add_child(card)
	scan_bar=_box("ScanBar",Vector3(0,-size_value.y*0.38,0.014),Vector3(size_value.x*0.82,0.018,0.007),_emissive(Color("#101820"),accent,2.0)); content_root.add_child(scan_bar)

func setup_sign(color:Color,width:float=2.4)->void:
	mode="sign"; accent=color
	content_root=Node3D.new(); content_root.name="AnimatedSign"; add_child(content_root)
	var bar:=_box("SignGlow",Vector3.ZERO,Vector3(width,0.075,0.035),_emissive(Color("#111820"),accent,2.1)); content_root.add_child(bar)
	for i in range(7):
		var dot:=MeshInstance3D.new(); var sphere:=SphereMesh.new(); sphere.radius=0.035; sphere.height=0.07; sphere.radial_segments=12; sphere.rings=6; dot.mesh=sphere; dot.position=Vector3(-width*0.38+i*(width*0.76/6.0),0.11,0.0); dot.material_override=_emissive(Color("#111820"),accent.lightened(0.12*(i%2)),1.4); content_root.add_child(dot)

func _process(delta:float)->void:
	phase+=delta
	match mode:
		"fan":
			if rotor!=null: rotor.rotation.z-=delta*7.5
		"screen":
			if scan_bar!=null:
				scan_bar.position.y=-0.22+fmod(phase*0.15,0.44)
				var m:=scan_bar.material_override as StandardMaterial3D
				if m!=null: m.emission_energy_multiplier=1.6+sin(phase*4.5)*0.35
		"sign":
			if content_root!=null: content_root.scale=Vector3.ONE*(1.0+sin(phase*2.0)*0.008)

func _box(n:String,pos:Vector3,size_value:Vector3,material:Material)->MeshInstance3D:
	var node:=MeshInstance3D.new(); node.name=n; node.position=pos; var mesh:=BoxMesh.new(); mesh.size=size_value; node.mesh=mesh; node.material_override=material; return node

func _mat(color:Color,roughness:float,metallic:float)->StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=color; m.roughness=roughness; m.metallic=metallic; return m

func _emissive(base:Color,glow:Color,energy:float)->StandardMaterial3D:
	var m:=_mat(base,0.22,0.15); m.emission_enabled=true; m.emission=glow; m.emission_energy_multiplier=energy; return m
