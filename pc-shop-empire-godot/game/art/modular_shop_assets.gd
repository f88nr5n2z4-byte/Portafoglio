extends RefCounted

# PC GAME EMPIRE — modular shop art kit.
# Every factory returns a reusable Node3D assembled from separate real-time meshes.
# No world raster is referenced here.

static func mat(color:Color, roughness:float=0.42, metallic:float=0.0, emission:Color=Color(0,0,0,0), emission_energy:float=0.0) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=roughness
	m.metallic=metallic
	if emission_energy>0.0:
		m.emission_enabled=true
		m.emission=emission
		m.emission_energy_multiplier=emission_energy
	return m

static func box(parent:Node3D,n:String,pos:Vector3,size:Vector3,material:Material) -> MeshInstance3D:
	var node:=MeshInstance3D.new(); node.name=n; node.position=pos
	var mesh:=BoxMesh.new(); mesh.size=size; node.mesh=mesh; node.material_override=material; parent.add_child(node)
	return node

static func cyl(parent:Node3D,n:String,pos:Vector3,radius:float,height:float,material:Material,rotation:Vector3=Vector3.ZERO) -> MeshInstance3D:
	var node:=MeshInstance3D.new(); node.name=n; node.position=pos; node.rotation_degrees=rotation
	var mesh:=CylinderMesh.new(); mesh.top_radius=radius; mesh.bottom_radius=radius; mesh.height=height; mesh.radial_segments=24; node.mesh=mesh; node.material_override=material; parent.add_child(node)
	return node

static func build_sales_counter() -> Node3D:
	var root:=Node3D.new(); root.name="SalesCounter_Final"
	var black:=mat(Color("#121820"),0.28,0.42)
	var metal:=mat(Color("#687481"),0.22,0.72)
	var panel:=mat(Color("#222c37"),0.36,0.24)
	var red:=mat(Color("#160b10"),0.20,0.25,Color("#ef3156"),2.8)
	box(root,"CounterBody",Vector3(0,0.52,0),Vector3(5.8,1.04,1.34),panel)
	box(root,"CounterToeKick",Vector3(0,0.10,0.08),Vector3(5.88,0.16,1.22),black)
	box(root,"CounterTop",Vector3(0,1.10,-0.02),Vector3(6.05,0.14,1.52),metal)
	box(root,"FrontInset",Vector3(0,0.55,0.69),Vector3(4.85,0.52,0.055),black)
	box(root,"FrontLight",Vector3(0,0.55,0.73),Vector3(3.85,0.045,0.025),red)
	for x in [-2.65,2.65]: box(root,"CornerTrim",Vector3(x,0.56,0.69),Vector3(0.10,0.82,0.06),metal)
	# workstation cluster
	build_monitor(root,Vector3(-1.45,1.52,-0.18),Color("#35bfe6"),0.86)
	build_monitor(root,Vector3(1.45,1.52,-0.18),Color("#ed365a"),0.86)
	box(root,"Keyboard",Vector3(-0.75,1.21,0.16),Vector3(0.92,0.045,0.34),black)
	box(root,"POSBase",Vector3(2.16,1.28,0.05),Vector3(0.40,0.22,0.34),black)
	box(root,"POSGlow",Vector3(2.16,1.40,0.23),Vector3(0.20,0.035,0.02),mat(Color("#0d1a14"),0.2,0.1,Color("#53e7aa"),2.2))
	return root

static func build_monitor(parent:Node3D,pos:Vector3,accent:Color,scale_value:float=1.0) -> Node3D:
	var root:=Node3D.new(); root.name="PremiumMonitor"; root.position=pos; root.scale=Vector3.ONE*scale_value; parent.add_child(root)
	var frame:=mat(Color("#10161d"),0.24,0.38)
	var screen:=mat(Color("#071018"),0.18,0.16,accent,1.75)
	box(root,"Panel",Vector3.ZERO,Vector3(1.22,0.72,0.075),frame)
	box(root,"Screen",Vector3(0,0,0.041),Vector3(1.10,0.61,0.015),screen)
	box(root,"Neck",Vector3(0,-0.49,-0.04),Vector3(0.10,0.34,0.10),frame)
	box(root,"Foot",Vector3(0,-0.67,-0.01),Vector3(0.52,0.045,0.30),frame)
	return root

static func build_wall_shelf(label:String,accent:Color) -> Node3D:
	var root:=Node3D.new(); root.name="Shelf_"+label
	var frame:=mat(Color("#1b242e"),0.34,0.55)
	var shelf:=mat(Color("#56616d"),0.30,0.65)
	var glow:=mat(Color("#111820"),0.20,0.20,accent,2.1)
	for x in [-1.12,1.12]: box(root,"Upright",Vector3(x,1.05,0),Vector3(0.10,2.10,0.50),frame)
	box(root,"Top",Vector3(0,2.05,0),Vector3(2.35,0.10,0.52),frame)
	box(root,"Back",Vector3(0,1.05,-0.23),Vector3(2.25,2.0,0.07),mat(Color("#202b36"),0.48,0.18))
	for row in range(4):
		var y:=0.22+row*0.52
		box(root,"Shelf",Vector3(0,y,0.0),Vector3(2.25,0.065,0.56),shelf)
		box(root,"ShelfGlow",Vector3(0,y+0.045,0.30),Vector3(2.05,0.025,0.018),glow)
		for col in range(4):
			var x:=-0.78+col*0.52
			var c:=accent.darkened(0.25+0.08*((row+col)%2))
			build_product_box(root,Vector3(x,y+0.24,0.08),Vector3(0.38,0.40,0.30),c,(row+col)%3)
	return root

static func build_product_box(parent:Node3D,pos:Vector3,size:Vector3,tone:Color,variant:int=0) -> Node3D:
	var root:=Node3D.new(); root.name="RetailBox"; root.position=pos; parent.add_child(root)
	box(root,"Carton",Vector3.ZERO,size,mat(tone,0.58,0.0))
	box(root,"BrandStripe",Vector3(0,0.04,size.z*0.51),Vector3(size.x*0.76,size.y*0.12,0.012),mat(Color("#0f141a"),0.4,0.0))
	var mark:=Color("#46c9ed") if variant==0 else (Color("#ef3e63") if variant==1 else Color("#ae6eff"))
	box(root,"TierMark",Vector3(-size.x*0.27,-size.y*0.20,size.z*0.52),Vector3(size.x*0.16,size.y*0.18,0.014),mat(mark,0.25,0.0,mark,0.7))
	return root

static func build_display_island(accent:Color,kind:String="pc") -> Node3D:
	var root:=Node3D.new(); root.name="DisplayIsland_"+kind
	var body:=mat(Color("#202a35"),0.30,0.42)
	var top:=mat(Color("#67727d"),0.20,0.70)
	var glow:=mat(Color("#10161e"),0.20,0.18,accent,2.4)
	box(root,"Base",Vector3(0,0.36,0),Vector3(3.3,0.72,1.72),body)
	box(root,"PlinthTop",Vector3(0,0.77,0),Vector3(3.45,0.10,1.82),top)
	box(root,"GlowFront",Vector3(0,0.56,0.88),Vector3(2.65,0.045,0.025),glow)
	box(root,"Inset",Vector3(0,0.34,0.865),Vector3(2.74,0.28,0.03),mat(Color("#0e141b"),0.38,0.2))
	if kind=="pc":
		build_gaming_pc(root,Vector3(-0.72,1.43,0),accent,2)
		build_gaming_pc(root,Vector3(0.78,1.43,0),accent.lightened(0.15),3)
	elif kind=="laptop":
		build_laptop(root,Vector3(-0.75,0.92,0),accent)
		build_laptop(root,Vector3(0.75,0.92,0),accent.lightened(0.16))
	else:
		build_keyboard(root,Vector3(-0.70,0.88,0.1),accent)
		build_headset(root,Vector3(0.72,1.05,0.05),accent)
	return root

static func build_gaming_pc(parent:Node3D,pos:Vector3,accent:Color,tier:int=2) -> Node3D:
	var root:=Node3D.new(); root.name="GamingPC_Tier%d"%tier; root.position=pos; parent.add_child(root)
	var chassis:=mat(Color("#111820"),0.24,0.50)
	var trim:=mat(Color("#56616d"),0.20,0.74)
	var glow:=mat(Color("#10151d"),0.18,0.25,accent,2.4)
	var w:=0.72+0.05*tier; var h:=1.25+0.06*tier; var d:=0.78
	box(root,"Chassis",Vector3.ZERO,Vector3(w,h,d),chassis)
	box(root,"FrontBezel",Vector3(0,0,d*0.50+0.018),Vector3(w*0.92,h*0.88,0.045),trim)
	box(root,"Glass",Vector3(w*0.50+0.018,0,0),Vector3(0.035,h*0.86,d*0.84),mat(Color(0.14,0.22,0.29,0.38),0.08,0.05))
	# interior motherboard / gpu / cooler silhouette
	box(root,"Motherboard",Vector3(w*0.34,0.06,-0.02),Vector3(0.025,h*0.58,d*0.55),mat(Color("#20362d"),0.36,0.22))
	box(root,"GPU",Vector3(w*0.33,-0.08,0.05),Vector3(0.07,0.18,d*0.58),mat(Color("#252d37"),0.28,0.48))
	cyl(root,"CPUFan",Vector3(w*0.38,0.25,-0.03),0.20,0.045,glow,Vector3(0,0,90))
	for i in range(2+(1 if tier>=3 else 0)):
		var fy:=-0.34+i*0.34
		cyl(root,"FrontFan",Vector3(0,fy,d*0.54),0.18,0.045,glow,Vector3(90,0,0))
	box(root,"PSUShroud",Vector3(0,-h*0.35,-0.05),Vector3(w*0.82,0.22,d*0.66),trim)
	return root

static func build_laptop(parent:Node3D,pos:Vector3,accent:Color) -> Node3D:
	var root:=Node3D.new(); root.name="GamingLaptop"; root.position=pos; parent.add_child(root)
	var shell:=mat(Color("#171e27"),0.25,0.55)
	box(root,"Base",Vector3(0,0,0.12),Vector3(0.92,0.055,0.62),shell)
	box(root,"KeyboardDeck",Vector3(0,0.035,0.05),Vector3(0.72,0.018,0.30),mat(Color("#0d131a"),0.3,0.25))
	var screen_root:=Node3D.new(); screen_root.position=Vector3(0,0.29,-0.18); screen_root.rotation_degrees=Vector3(-15,0,0); root.add_child(screen_root)
	box(screen_root,"Lid",Vector3.ZERO,Vector3(0.94,0.58,0.04),shell)
	box(screen_root,"Screen",Vector3(0,0,0.025),Vector3(0.84,0.48,0.012),mat(Color("#071018"),0.15,0.12,accent,1.7))
	return root

static func build_keyboard(parent:Node3D,pos:Vector3,accent:Color) -> Node3D:
	var root:=Node3D.new(); root.name="Keyboard"; root.position=pos; parent.add_child(root)
	box(root,"Deck",Vector3.ZERO,Vector3(0.82,0.055,0.30),mat(Color("#111820"),0.32,0.32))
	for row in range(4):
		for col in range(10):
			box(root,"Key",Vector3(-0.34+col*0.075,0.04,-0.10+row*0.065),Vector3(0.055,0.025,0.045),mat(accent.darkened(0.35+0.03*((row+col)%3)),0.35,0.05,accent,0.18))
	return root

static func build_mouse(parent:Node3D,pos:Vector3,accent:Color) -> Node3D:
	var root:=Node3D.new(); root.name="GamingMouse"; root.position=pos; parent.add_child(root)
	var shell:=SphereMesh.new(); shell.radius=0.11; shell.height=0.16; shell.radial_segments=20; shell.rings=10
	var node:=MeshInstance3D.new(); node.mesh=shell; node.scale=Vector3(0.72,0.42,1.10); node.material_override=mat(Color("#131a22"),0.25,0.35); root.add_child(node)
	box(root,"Light",Vector3(0,0.045,0.03),Vector3(0.02,0.015,0.09),mat(Color("#111820"),0.2,0.1,accent,2.0))
	return root

static func build_headset(parent:Node3D,pos:Vector3,accent:Color) -> Node3D:
	var root:=Node3D.new(); root.name="Headset"; root.position=pos; parent.add_child(root)
	var dark:=mat(Color("#151c24"),0.32,0.28)
	for x in [-0.18,0.18]:
		cyl(root,"EarCup",Vector3(x,0,0),0.14,0.08,dark,Vector3(0,0,90))
		cyl(root,"EarGlow",Vector3(x,0.0,0.045),0.07,0.018,mat(Color("#111820"),0.2,0.1,accent,1.8),Vector3(90,0,0))
	box(root,"Band",Vector3(0,0.22,0),Vector3(0.48,0.055,0.055),dark)
	return root

static func build_peripheral_display(accent:Color) -> Node3D:
	var root:=Node3D.new(); root.name="PeripheralDisplay_Final"
	var back:=mat(Color("#1d2731"),0.34,0.42)
	var metal:=mat(Color("#586572"),0.22,0.68)
	box(root,"BackPanel",Vector3(0,1.15,-0.18),Vector3(2.5,2.3,0.14),back)
	box(root,"Header",Vector3(0,2.22,-0.08),Vector3(2.55,0.15,0.18),mat(Color("#111820"),0.2,0.25,accent,1.8))
	for y in [0.48,1.15,1.80]: box(root,"Rail",Vector3(0,y,-0.02),Vector3(2.25,0.06,0.28),metal)
	build_keyboard(root,Vector3(-0.52,1.18,0.12),accent)
	build_mouse(root,Vector3(0.72,1.22,0.12),accent)
	build_headset(root,Vector3(0.64,1.82,0.08),accent)
	return root

static func build_chair(accent:Color) -> Node3D:
	var root:=Node3D.new(); root.name="GamingChair_Final"
	var fabric:=mat(Color("#191f28"),0.62,0.05)
	var frame:=mat(Color("#3d4753"),0.28,0.64)
	box(root,"Seat",Vector3(0,0.55,0),Vector3(0.72,0.15,0.72),fabric)
	box(root,"Back",Vector3(0,1.18,-0.29),Vector3(0.70,1.05,0.16),fabric)
	box(root,"Accent",Vector3(0,1.30,-0.205),Vector3(0.38,0.52,0.025),mat(accent.darkened(0.35),0.48,0.05))
	for x in [-0.42,0.42]: box(root,"Arm",Vector3(x,0.78,-0.02),Vector3(0.10,0.10,0.52),frame)
	box(root,"Stem",Vector3(0,0.28,0),Vector3(0.10,0.45,0.10),frame)
	for a in range(5):
		var angle:=float(a)*TAU/5.0
		box(root,"Leg",Vector3(cos(angle)*0.26,0.08,sin(angle)*0.26),Vector3(0.38,0.05,0.07),frame)
	return root

static func build_plant() -> Node3D:
	var root:=Node3D.new(); root.name="Plant_Final"
	cyl(root,"Pot",Vector3(0,0.22,0),0.24,0.44,mat(Color("#303a44"),0.52,0.12))
	for i in range(7):
		var a:=float(i)*TAU/7.0
		var leaf:=box(root,"Leaf",Vector3(cos(a)*0.15,0.64,sin(a)*0.15),Vector3(0.14,0.62,0.06),mat(Color("#315f4a").lightened(0.05*(i%3)),0.68,0.0))
		leaf.rotation_degrees=Vector3(0,rad_to_deg(a),18 if i%2==0 else -18)
	return root

static func build_brand_totem(accent:Color) -> Node3D:
	var root:=Node3D.new(); root.name="EmpireBrandTotem"
	var dark:=mat(Color("#111820"),0.24,0.45)
	box(root,"Body",Vector3(0,1.15,0),Vector3(0.90,2.30,0.42),dark)
	box(root,"GlowCore",Vector3(0,1.30,0.225),Vector3(0.54,1.20,0.02),mat(Color("#111820"),0.18,0.18,accent,2.4))
	box(root,"Cap",Vector3(0,2.36,0),Vector3(1.02,0.10,0.50),mat(Color("#67727e"),0.22,0.72))
	return root
