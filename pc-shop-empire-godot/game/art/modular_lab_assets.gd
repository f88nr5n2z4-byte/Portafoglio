extends RefCounted

const ShopAssets = preload("res://game/art/modular_shop_assets.gd")

static func mat(color:Color,roughness:float=0.42,metallic:float=0.0,emission:Color=Color(0,0,0,0),energy:float=0.0)->StandardMaterial3D:
	return ShopAssets.mat(color,roughness,metallic,emission,energy)

static func box(parent:Node3D,n:String,pos:Vector3,size:Vector3,material:Material)->MeshInstance3D:
	return ShopAssets.box(parent,n,pos,size,material)

static func cyl(parent:Node3D,n:String,pos:Vector3,r:float,h:float,material:Material,rotation:Vector3=Vector3.ZERO)->MeshInstance3D:
	return ShopAssets.cyl(parent,n,pos,r,h,material,rotation)

static func build_workbench()->Node3D:
	var root:=Node3D.new(); root.name="Workbench_Final"
	var frame:=mat(Color("#26333e"),0.34,0.40)
	var steel:=mat(Color("#7b8893"),0.28,0.44)
	var top:=mat(Color("#3b4651"),0.36,0.40)
	var rubber:=mat(Color("#102127"),0.68,0.0)
	box(root,"Frame",Vector3(0,0.55,0),Vector3(5.7,1.10,1.62),frame)
	box(root,"Top",Vector3(0,1.16,0),Vector3(5.95,0.14,1.84),top)
	box(root,"ESDMat",Vector3(0.28,1.245,0),Vector3(3.7,0.025,1.24),rubber)
	# Drawer banks
	for side in [-2.35,2.35]:
		box(root,"DrawerBank",Vector3(side,0.60,0),Vector3(0.82,0.92,1.35),mat(Color("#2a3540"),0.34,0.52))
		for y in [0.32,0.62,0.92]:
			box(root,"DrawerFace",Vector3(side,y,0.695),Vector3(0.72,0.20,0.035),mat(Color("#37434f"),0.30,0.55))
			box(root,"DrawerHandle",Vector3(side,y,0.73),Vector3(0.28,0.035,0.035),steel)
	# Rear service rail and task light
	for x in [-2.45,2.45]: box(root,"RearPost",Vector3(x,2.0,-0.72),Vector3(0.08,1.65,0.08),steel)
	box(root,"RearRail",Vector3(0,2.74,-0.72),Vector3(5.0,0.08,0.08),steel)
	box(root,"TaskLightHousing",Vector3(0,2.62,-0.62),Vector3(3.70,0.17,0.24),mat(Color("#17212a"),0.34,0.38))
	box(root,"TaskLightDiffuser",Vector3(0,2.53,-0.53),Vector3(3.18,0.025,0.11),mat(Color("#cad8df"),0.28,0.05,Color("#dff3ff"),0.90))
	# Parts trays and tool dock
	for i in range(4):
		box(root,"PartsTray",Vector3(-1.15+i*0.55,1.32,0.44),Vector3(0.46,0.09,0.34),mat(Color("#444f5a"),0.46,0.34))
	for i in range(3):
		build_screwdriver(root,Vector3(-2.05+i*0.18,1.43,-0.38),Color("#ec365b") if i%2==0 else Color("#36bee7"))
	return root

static func build_tool_wall()->Node3D:
	var root:=Node3D.new(); root.name="ToolWall_Final"
	var board:=mat(Color("#24313c"),0.48,0.24)
	var metal:=mat(Color("#7b8792"),0.23,0.78)
	box(root,"Pegboard",Vector3(0,1.35,0),Vector3(6.6,2.55,0.12),board)
	box(root,"FrameTop",Vector3(0,2.66,0),Vector3(6.8,0.08,0.18),metal)
	box(root,"FrameBottom",Vector3(0,0.05,0),Vector3(6.8,0.08,0.18),metal)
	for x in [-3.35,3.35]: box(root,"FrameSide",Vector3(x,1.35,0),Vector3(0.08,2.62,0.18),metal)
	# perforation field
	for row in range(7):
		for col in range(18):
			cyl(root,"PegHole",Vector3(-2.98+col*0.35,0.35+row*0.32,0.07),0.018,0.015,mat(Color("#0e151c"),0.55,0.10),Vector3(90,0,0))
	# tools
	for i in range(6): build_screwdriver(root,Vector3(-2.45+i*0.40,1.65,0.16),Color("#e9365b") if i%2==0 else Color("#3fc0e8"))
	build_pliers(root,Vector3(0.55,1.55,0.16),Color("#ee3b5d"))
	build_pliers(root,Vector3(1.10,1.55,0.16),Color("#32bce5"))
	for i in range(3): build_cable_roll(root,Vector3(2.0+i*0.58,1.45,0.16),Color("#f13c62") if i==0 else (Color("#38bce5") if i==1 else Color("#a967ef")))
	return root

static func build_screwdriver(parent:Node3D,pos:Vector3,accent:Color)->Node3D:
	var root:=Node3D.new(); root.name="Screwdriver"; root.position=pos; parent.add_child(root)
	cyl(root,"Handle",Vector3(0,0.12,0),0.055,0.28,mat(accent,0.42,0.08))
	cyl(root,"Shaft",Vector3(0,-0.12,0),0.014,0.25,mat(Color("#9aa4ad"),0.18,0.82))
	return root

static func build_pliers(parent:Node3D,pos:Vector3,accent:Color)->Node3D:
	var root:=Node3D.new(); root.name="Pliers"; root.position=pos; parent.add_child(root)
	for x in [-0.055,0.055]:
		var h:=box(root,"Handle",Vector3(x,-0.10,0),Vector3(0.075,0.34,0.055),mat(accent,0.46,0.05)); h.rotation_degrees.z=12 if x<0 else -12
		var jaw:=box(root,"Jaw",Vector3(x*0.55,0.16,0),Vector3(0.045,0.24,0.045),mat(Color("#8d99a3"),0.20,0.80)); jaw.rotation_degrees.z=-8 if x<0 else 8
	cyl(root,"Pivot",Vector3(0,0.03,0.035),0.045,0.03,mat(Color("#727e89"),0.20,0.82),Vector3(90,0,0))
	return root

static func build_cable_roll(parent:Node3D,pos:Vector3,accent:Color)->Node3D:
	var root:=Node3D.new(); root.name="CableRoll"; root.position=pos; parent.add_child(root)
	cyl(root,"Outer",Vector3.ZERO,0.18,0.07,mat(Color("#171e26"),0.44,0.16),Vector3(90,0,0))
	cyl(root,"Core",Vector3(0,0,0.04),0.085,0.075,mat(accent,0.40,0.05,accent,0.28),Vector3(90,0,0))
	return root

static func build_component_tray()->Node3D:
	var root:=Node3D.new(); root.name="ComponentTray_Final"
	box(root,"Tray",Vector3(0,0.06,0),Vector3(2.0,0.12,1.10),mat(Color("#3a4652"),0.44,0.34))
	# GPU prop
	var gpu:=Node3D.new(); gpu.name="GPUProp"; gpu.position=Vector3(-0.40,0.18,0); root.add_child(gpu)
	box(gpu,"Shroud",Vector3.ZERO,Vector3(1.08,0.16,0.42),mat(Color("#1c242d"),0.26,0.46))
	for x in [-0.27,0.27]: cyl(gpu,"Fan",Vector3(x,0.10,0.22),0.14,0.035,mat(Color("#0c1218"),0.33,0.24),Vector3(90,0,0))
	box(gpu,"Accent",Vector3(0,0.10,0.245),Vector3(0.66,0.025,0.015),mat(Color("#111820"),0.2,0.12,Color("#ee365c"),1.6))
	# RAM kits
	for i in range(2):
		box(root,"RAM",Vector3(0.55+i*0.20,0.17,-0.15),Vector3(0.10,0.26,0.46),mat(Color("#263441"),0.28,0.38))
		box(root,"RAMGlow",Vector3(0.55+i*0.20,0.31,-0.15),Vector3(0.08,0.025,0.38),mat(Color("#111820"),0.2,0.1,Color("#37bfe7"),1.4))
	return root

static func build_open_pc()->Node3D:
	var root:=Node3D.new(); root.name="OpenPC_Final"
	var chassis:=mat(Color("#151c24"),0.30,0.55)
	var steel:=mat(Color("#596571"),0.24,0.74)
	box(root,"Base",Vector3(0,-0.52,0),Vector3(1.05,0.08,0.85),chassis)
	box(root,"Back",Vector3(0,0,-0.40),Vector3(1.05,1.10,0.06),chassis)
	box(root,"Front",Vector3(0,0,0.40),Vector3(1.05,1.10,0.06),steel)
	box(root,"Motherboard",Vector3(0.20,0,-0.34),Vector3(0.55,0.72,0.025),mat(Color("#244235"),0.38,0.20))
	box(root,"GPU",Vector3(0.10,-0.15,-0.20),Vector3(0.68,0.14,0.22),mat(Color("#242c36"),0.27,0.48))
	cyl(root,"Cooler",Vector3(0.18,0.22,-0.29),0.18,0.08,mat(Color("#111820"),0.28,0.40,Color("#e83b5d"),0.8),Vector3(0,0,90))
	box(root,"PSU",Vector3(-0.22,-0.38,-0.15),Vector3(0.44,0.22,0.42),mat(Color("#202832"),0.36,0.48))
	return root

static func build_diagnostics_station()->Node3D:
	var root:=Node3D.new(); root.name="DiagnosticsStation_Final"
	var frame:=mat(Color("#26313c"),0.32,0.55)
	var metal:=mat(Color("#788691"),0.29,0.40)
	box(root,"Desk",Vector3(0,0.55,0),Vector3(2.45,1.1,1.20),frame)
	box(root,"Top",Vector3(0,1.15,0),Vector3(2.60,0.12,1.32),metal)
	ShopAssets.build_monitor(root,Vector3(-0.38,1.58,-0.16),Color("#38c0e9"),0.90)
	box(root,"Analyzer",Vector3(0.72,1.38,-0.12),Vector3(0.48,0.36,0.42),mat(Color("#161e27"),0.30,0.40))
	box(root,"AnalyzerScreen",Vector3(0.72,1.42,0.105),Vector3(0.32,0.16,0.015),mat(Color("#071018"),0.18,0.10,Color("#54e8a9"),1.8))
	ShopAssets.build_keyboard(root,Vector3(-0.35,1.23,0.35),Color("#36bfe7"))
	return root

static func build_lab_cabinet(accent:Color)->Node3D:
	var root:=Node3D.new(); root.name="LabCabinet_Final"
	var body:=mat(Color("#25303b"),0.34,0.58)
	var face:=mat(Color("#333f4b"),0.30,0.52)
	var handle:=mat(Color("#77838e"),0.20,0.78)
	box(root,"Body",Vector3(0,0.85,0),Vector3(1.30,1.70,1.02),body)
	for i in range(4):
		var y:=0.25+i*0.38
		box(root,"Drawer",Vector3(0,y,0.525),Vector3(1.15,0.30,0.035),face)
		box(root,"Handle",Vector3(0,y,0.565),Vector3(0.30,0.035,0.035),handle)
	box(root,"Status",Vector3(0,1.54,0.555),Vector3(0.68,0.035,0.018),mat(Color("#111820"),0.2,0.1,accent,1.5))
	return root

static func build_storage_shelf()->Node3D:
	var root:=Node3D.new(); root.name="LabStorage_Final"
	var frame:=mat(Color("#4f5d69"),0.24,0.72)
	for x in [-1.20,1.20]: box(root,"Post",Vector3(x,1.25,0),Vector3(0.08,2.5,0.72),frame)
	for y in [0.12,0.72,1.32,1.92,2.48]:
		box(root,"Shelf",Vector3(0,y,0),Vector3(2.48,0.07,0.80),frame)
		if y<2.4:
			for col in range(3):
				var accent:=Color("#e43a5c") if (col+int(y*10))%2==0 else Color("#35bce5")
				ShopAssets.build_product_box(root,Vector3(-0.70+col*0.70,y+0.24,0),Vector3(0.48,0.38,0.50),accent,col%3)
	return root
