extends RefCounted

# PC GAME EMPIRE — modular shop art kit.
# Every factory returns a reusable Node3D assembled from separate real-time meshes.
# No world raster is referenced here.

static var _bevel_mesh_cache:Dictionary = {}
static var _plain_mesh_cache:Dictionary = {}
static var _cylinder_mesh_cache:Dictionary = {}
static var _material_cache:Dictionary = {}

static func mat(color:Color, roughness:float=0.42, metallic:float=0.0, emission:Color=Color(0,0,0,0), emission_energy:float=0.0) -> StandardMaterial3D:
	var key:="%.3f_%.3f_%.3f_%.3f__%.3f_%.3f__%.3f_%.3f_%.3f_%.3f__%.3f"%[color.r,color.g,color.b,color.a,roughness,metallic,emission.r,emission.g,emission.b,emission.a,emission_energy]
	if _material_cache.has(key): return _material_cache[key] as StandardMaterial3D
	var m:=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=roughness
	m.metallic=metallic
	if color.a<0.999:
		m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode=BaseMaterial3D.CULL_DISABLED
	if emission_energy>0.0:
		m.emission_enabled=true
		m.emission=emission
		m.emission_energy_multiplier=emission_energy
	_material_cache[key]=m
	return m

static func box(parent:Node3D,n:String,pos:Vector3,size:Vector3,material:Material) -> MeshInstance3D:
	var node:=MeshInstance3D.new(); node.name=n; node.position=pos
	var shortest:float=minf(size.x,minf(size.y,size.z))
	if shortest>=0.055:
		var bevel:float=clampf(shortest*0.18,0.012,0.055)
		node.mesh=_beveled_box_mesh(size,bevel)
	else:
		node.mesh=_plain_box_mesh(size)
	node.material_override=material; parent.add_child(node)
	return node

static func _plain_box_mesh(size:Vector3) -> BoxMesh:
	var key:="%.3f_%.3f_%.3f"%[size.x,size.y,size.z]
	if _plain_mesh_cache.has(key): return _plain_mesh_cache[key] as BoxMesh
	var mesh:=BoxMesh.new(); mesh.size=size; _plain_mesh_cache[key]=mesh; return mesh

static func _beveled_box_mesh(size:Vector3,bevel:float) -> ArrayMesh:
	var key:="%.3f_%.3f_%.3f_%.3f"%[size.x,size.y,size.z,bevel]
	if _bevel_mesh_cache.has(key): return _bevel_mesh_cache[key] as ArrayMesh
	var hx:float=size.x*0.5; var hy:float=size.y*0.5; var hz:float=size.z*0.5
	var bx:float=minf(bevel,hx*0.48); var by:float=minf(bevel,hy*0.48); var bz:float=minf(bevel,hz*0.48)
	var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Six broad faces.
	for sx in [-1.0,1.0]:
		_add_polygon(st,[Vector3(sx*hx,-hy+by,-hz+bz),Vector3(sx*hx,hy-by,-hz+bz),Vector3(sx*hx,hy-by,hz-bz),Vector3(sx*hx,-hy+by,hz-bz)])
	for sy in [-1.0,1.0]:
		_add_polygon(st,[Vector3(-hx+bx,sy*hy,-hz+bz),Vector3(-hx+bx,sy*hy,hz-bz),Vector3(hx-bx,sy*hy,hz-bz),Vector3(hx-bx,sy*hy,-hz+bz)])
	for sz in [-1.0,1.0]:
		_add_polygon(st,[Vector3(-hx+bx,-hy+by,sz*hz),Vector3(hx-bx,-hy+by,sz*hz),Vector3(hx-bx,hy-by,sz*hz),Vector3(-hx+bx,hy-by,sz*hz)])
	# Twelve chamfered edges.
	for sx in [-1.0,1.0]:
		for sy in [-1.0,1.0]:
			_add_polygon(st,[Vector3(sx*hx,sy*(hy-by),-hz+bz),Vector3(sx*(hx-bx),sy*hy,-hz+bz),Vector3(sx*(hx-bx),sy*hy,hz-bz),Vector3(sx*hx,sy*(hy-by),hz-bz)])
	for sx in [-1.0,1.0]:
		for sz in [-1.0,1.0]:
			_add_polygon(st,[Vector3(sx*hx,-hy+by,sz*(hz-bz)),Vector3(sx*(hx-bx),-hy+by,sz*hz),Vector3(sx*(hx-bx),hy-by,sz*hz),Vector3(sx*hx,hy-by,sz*(hz-bz))])
	for sy in [-1.0,1.0]:
		for sz in [-1.0,1.0]:
			_add_polygon(st,[Vector3(-hx+bx,sy*hy,sz*(hz-bz)),Vector3(-hx+bx,sy*(hy-by),sz*hz),Vector3(hx-bx,sy*(hy-by),sz*hz),Vector3(hx-bx,sy*hy,sz*(hz-bz))])
	# Eight clipped corners close the convex hull.
	for sx in [-1.0,1.0]:
		for sy in [-1.0,1.0]:
			for sz in [-1.0,1.0]:
				_add_polygon(st,[Vector3(sx*hx,sy*(hy-by),sz*(hz-bz)),Vector3(sx*(hx-bx),sy*hy,sz*(hz-bz)),Vector3(sx*(hx-bx),sy*(hy-by),sz*hz)])
	var result:ArrayMesh=st.commit()
	_bevel_mesh_cache[key]=result
	return result

static func _add_polygon(st:SurfaceTool,points:Array) -> void:
	if points.size()<3: return
	var center:=Vector3.ZERO
	for point:Vector3 in points: center+=point
	center/=float(points.size())
	var normal:Vector3=(points[1]-points[0]).cross(points[2]-points[0]).normalized()
	if normal.dot(center)<0.0:
		points.reverse()
		normal=(points[1]-points[0]).cross(points[2]-points[0]).normalized()
	for i in range(1,points.size()-1):
		for point:Vector3 in [points[0],points[i],points[i+1]]:
			st.set_normal(normal); st.add_vertex(point)

static func label3d(parent:Node3D,text_value:String,pos:Vector3,rotation:Vector3=Vector3.ZERO,font_size:int=28,tone:Color=Color.WHITE,pixel_size:float=0.0025) -> Label3D:
	var label:=Label3D.new(); label.name="Label_"+text_value.replace(" ","_"); label.text=text_value; label.position=pos; label.rotation_degrees=rotation
	label.font_size=font_size; label.pixel_size=pixel_size; label.modulate=tone; label.outline_size=8; label.outline_modulate=Color(0.01,0.015,0.02,0.92); label.no_depth_test=false
	parent.add_child(label); return label

static func cyl(parent:Node3D,n:String,pos:Vector3,radius:float,height:float,material:Material,rotation:Vector3=Vector3.ZERO) -> MeshInstance3D:
	var node:=MeshInstance3D.new(); node.name=n; node.position=pos; node.rotation_degrees=rotation
	var key:="%.3f_%.3f"%[radius,height]
	var mesh:CylinderMesh
	if _cylinder_mesh_cache.has(key): mesh=_cylinder_mesh_cache[key] as CylinderMesh
	else:
		mesh=CylinderMesh.new(); mesh.top_radius=radius; mesh.bottom_radius=radius; mesh.height=height; mesh.radial_segments=24; _cylinder_mesh_cache[key]=mesh
	node.mesh=mesh; node.material_override=material; parent.add_child(node)
	return node

static func build_sales_counter() -> Node3D:
	var root:=Node3D.new(); root.name="SalesCounter_Final"
	var black:=mat(Color("#121820"),0.28,0.42)
	var metal:=mat(Color("#7d8995"),0.28,0.38)
	var panel:=mat(Color("#222c37"),0.36,0.24)
	var red:=mat(Color("#160b10"),0.20,0.25,Color("#ef3156"),1.45)
	box(root,"CounterBody",Vector3(0,0.52,0),Vector3(5.8,1.04,1.34),panel)
	box(root,"CounterToeKick",Vector3(0,0.10,0.08),Vector3(5.88,0.16,1.22),black)
	box(root,"CounterTop",Vector3(0,1.10,-0.02),Vector3(6.05,0.14,1.52),metal)
	box(root,"FrontInset",Vector3(0,0.55,0.69),Vector3(4.85,0.58,0.055),black)
	box(root,"FrontLight",Vector3(0,0.31,0.73),Vector3(4.30,0.035,0.025),red)
	for x in [-2.65,2.65]: box(root,"CornerTrim",Vector3(x,0.56,0.69),Vector3(0.10,0.82,0.06),metal)
	box(root,"BrandPlate",Vector3(0,0.65,0.735),Vector3(2.64,0.38,0.035),mat(Color("#19222c"),0.30,0.28))
	label3d(root,"PC GAME EMPIRE",Vector3(0,0.66,0.758),Vector3.ZERO,34,Color("#f5f8fa"),0.0042)
	label3d(root,"SERVICE  •  CHECKOUT",Vector3(0,0.45,0.758),Vector3.ZERO,19,Color("#ef5470"),0.0028)
	# workstation cluster
	build_monitor(root,Vector3(-1.45,1.52,-0.18),Color("#35bfe6"),0.86)
	build_monitor(root,Vector3(1.45,1.52,-0.18),Color("#ed365a"),0.86)
	box(root,"Keyboard",Vector3(-0.75,1.21,0.16),Vector3(0.92,0.045,0.34),black)
	box(root,"POSBase",Vector3(2.16,1.28,0.05),Vector3(0.40,0.22,0.34),black)
	box(root,"POSGlow",Vector3(2.16,1.40,0.23),Vector3(0.20,0.035,0.02),mat(Color("#0d1a14"),0.2,0.1,Color("#53e7aa"),1.25))
	for x in [-2.78,2.78]:
		box(root,"CounterEndCap",Vector3(x,0.58,0),Vector3(0.12,0.86,1.25),metal)
	return root

static func build_monitor(parent:Node3D,pos:Vector3,accent:Color,scale_value:float=1.0) -> Node3D:
	var root:=Node3D.new(); root.name="PremiumMonitor"; root.position=pos; root.scale=Vector3.ONE*scale_value; parent.add_child(root)
	var frame:=mat(Color("#10161d"),0.24,0.38)
	var screen:=mat(Color("#071018"),0.18,0.16,accent,1.15)
	box(root,"Panel",Vector3.ZERO,Vector3(1.22,0.72,0.075),frame)
	box(root,"Screen",Vector3(0,0,0.041),Vector3(1.10,0.61,0.015),screen)
	box(root,"Neck",Vector3(0,-0.49,-0.04),Vector3(0.10,0.34,0.10),frame)
	box(root,"Foot",Vector3(0,-0.67,-0.01),Vector3(0.52,0.045,0.30),frame)
	return root

static func build_wall_shelf(label:String,accent:Color) -> Node3D:
	var root:=Node3D.new(); root.name="Shelf_"+label
	var frame:=mat(Color("#1b242e"),0.34,0.55)
	var shelf:=mat(Color("#56616d"),0.30,0.65)
	var glow:=mat(Color("#111820"),0.20,0.20,accent,1.20)
	for x in [-1.12,1.12]: box(root,"Upright",Vector3(x,1.05,0),Vector3(0.10,2.10,0.50),frame)
	box(root,"Top",Vector3(0,2.05,0),Vector3(2.35,0.10,0.52),frame)
	box(root,"Back",Vector3(0,1.05,-0.23),Vector3(2.25,2.0,0.07),mat(Color("#202b36"),0.48,0.18))
	box(root,"CategoryHeader",Vector3(0,2.21,0.04),Vector3(2.38,0.28,0.54),mat(Color("#111820"),0.26,0.38))
	box(root,"CategoryAccent",Vector3(0,2.07,0.325),Vector3(2.12,0.035,0.022),glow)
	label3d(root,label,Vector3(0,2.22,0.326),Vector3.ZERO,34,Color("#f2f6f8"),0.0045)
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
	var product_name:="RTX" if variant==0 else ("CPU" if variant==1 else "SSD")
	label3d(root,product_name,Vector3(size.x*0.08,0.04,size.z*0.52+0.009),Vector3.ZERO,22,Color("#f4f7f9"),0.00215)
	return root

static func build_display_island(accent:Color,kind:String="pc") -> Node3D:
	var root:=Node3D.new(); root.name="DisplayIsland_"+kind
	var body:=mat(Color("#273441"),0.34,0.28)
	var top:=mat(Color("#7c8994"),0.30,0.38)
	var glow:=mat(Color("#10161e"),0.20,0.18,accent,1.35)
	box(root,"Base",Vector3(0,0.36,0),Vector3(3.3,0.72,1.72),body)
	box(root,"PlinthTop",Vector3(0,0.77,0),Vector3(3.45,0.10,1.82),top)
	box(root,"GlowFront",Vector3(0,0.56,0.88),Vector3(2.65,0.045,0.025),glow)
	box(root,"Inset",Vector3(0,0.34,0.865),Vector3(2.74,0.28,0.03),mat(Color("#0e141b"),0.38,0.2))
	var category:="CUSTOM PCS" if kind=="pc" else ("LAPTOPS" if kind=="laptop" else "PERIPHERALS")
	label3d(root,category,Vector3(0,0.37,0.887),Vector3.ZERO,30,Color("#f4f7f9"),0.0040)
	if kind=="pc":
		build_gaming_pc(root,Vector3(-0.72,1.43,0),accent,2)
		build_gaming_pc(root,Vector3(0.78,1.43,0),accent.lightened(0.15),3)
		build_price_card(root,Vector3(-0.72,0.91,0.60),"PERFORMANCE",accent)
		build_price_card(root,Vector3(0.78,0.91,0.60),"ENTHUSIAST",accent.lightened(0.12))
	elif kind=="laptop":
		build_laptop(root,Vector3(-1.02,0.92,0),accent)
		build_laptop(root,Vector3(0,0.92,0),accent.lightened(0.10))
		build_laptop(root,Vector3(1.02,0.92,0),accent.lightened(0.20))
	else:
		build_keyboard(root,Vector3(-0.82,0.88,0.1),accent)
		build_mouse(root,Vector3(0.05,0.92,0.18),accent.lightened(0.1))
		build_headset(root,Vector3(0.82,1.05,0.05),accent)
	return root

static func build_price_card(parent:Node3D,pos:Vector3,title:String,accent:Color) -> Node3D:
	var root:=Node3D.new(); root.name="SpecCard_"+title; root.position=pos; root.rotation_degrees.x=-16; parent.add_child(root)
	box(root,"Card",Vector3.ZERO,Vector3(0.72,0.30,0.035),mat(Color("#f1f4f6"),0.64,0.02))
	box(root,"Accent",Vector3(0,-0.12,0.021),Vector3(0.62,0.025,0.012),mat(accent,0.30,0.06,accent,0.42))
	label3d(root,title,Vector3(0,0.035,0.023),Vector3.ZERO,18,Color("#17202a"),0.0025)
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
	# Three real MultiMesh batches replace forty individual key draw resources.
	for variant in range(3):
		var transforms:Array[Transform3D]=[]
		for row in range(4):
			for col in range(10):
				if (row+col)%3==variant:
					transforms.append(Transform3D(Basis.IDENTITY,Vector3(-0.34+col*0.075,0.04,-0.10+row*0.065)))
		var multi:=MultiMesh.new(); multi.transform_format=MultiMesh.TRANSFORM_3D; multi.mesh=_plain_box_mesh(Vector3(0.055,0.025,0.045)); multi.instance_count=transforms.size()
		for index in range(transforms.size()): multi.set_instance_transform(index,transforms[index])
		var batch:=MultiMeshInstance3D.new(); batch.name="KeyBatch_%d"%variant; batch.multimesh=multi; batch.material_override=mat(accent.darkened(0.35+0.03*variant),0.35,0.05,accent,0.18); root.add_child(batch)
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
	box(root,"Header",Vector3(0,2.22,-0.08),Vector3(2.55,0.30,0.18),mat(Color("#111820"),0.2,0.25,accent,1.15))
	label3d(root,"PERIPHERALS",Vector3(0,2.23,0.018),Vector3.ZERO,34,Color("#f4f7f9"),0.0044)
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

static func build_brand_totem(accent:Color,title:String="PLAY") -> Node3D:
	var root:=Node3D.new(); root.name="EmpireBrandTotem"
	var dark:=mat(Color("#111820"),0.24,0.45)
	box(root,"Body",Vector3(0,1.15,0),Vector3(0.90,2.30,0.42),dark)
	box(root,"GlowCore",Vector3(0,1.30,0.225),Vector3(0.54,1.20,0.02),mat(Color("#111820"),0.18,0.18,accent,1.25))
	box(root,"Cap",Vector3(0,2.36,0),Vector3(1.02,0.10,0.50),mat(Color("#67727e"),0.22,0.72))
	label3d(root,title,Vector3(0,1.36,0.242),Vector3.ZERO,31,Color("#f5f8fa"),0.0040)
	label3d(root,"PCGE",Vector3(0,0.83,0.242),Vector3.ZERO,21,accent.lightened(0.18),0.0030)
	return root

static func build_shop_terminal(accent:Color=Color("#38c2e9")) -> Node3D:
	var root:=Node3D.new(); root.name="StoreTerminal_Final"
	var shell:=mat(Color("#202a35"),0.34,0.42)
	var dark:=mat(Color("#10171e"),0.42,0.22)
	var metal:=mat(Color("#7b8995"),0.29,0.40)
	var glow:=mat(Color("#101820"),0.20,0.14,accent,1.10)
	box(root,"TerminalBody",Vector3(0,0.50,0),Vector3(2.05,1.0,1.18),shell)
	box(root,"TerminalToeKick",Vector3(0,0.10,0.06),Vector3(1.88,0.16,1.03),dark)
	box(root,"TerminalTop",Vector3(0,1.05,-0.02),Vector3(2.22,0.12,1.32),metal)
	box(root,"TerminalFrontInset",Vector3(0,0.54,0.605),Vector3(1.58,0.46,0.035),dark)
	box(root,"TerminalFrontGlow",Vector3(0,0.31,0.627),Vector3(1.46,0.03,0.018),glow)
	label3d(root,"CATALOGO",Vector3(0,0.59,0.629),Vector3.ZERO,29,Color("#f4f8fa"),0.0040)
	label3d(root,"HARDWARE  •  BUILD",Vector3(0,0.42,0.629),Vector3.ZERO,17,accent.lightened(0.18),0.0025)
	build_monitor(root,Vector3(0,1.52,-0.13),accent,0.94)
	build_keyboard(root,Vector3(-0.18,1.16,0.25),accent)
	build_mouse(root,Vector3(0.67,1.19,0.23),Color("#ef3c60"))
	box(root,"CablePort",Vector3(-0.76,1.12,-0.42),Vector3(0.18,0.035,0.20),dark)
	return root

static func build_consultation_table() -> Node3D:
	var root:=Node3D.new(); root.name="ConsultationTable_Final"
	var dark:=mat(Color("#1b2530"),0.40,0.34)
	var metal:=mat(Color("#74828e"),0.31,0.36)
	box(root,"TableTop",Vector3(0,0.78,0),Vector3(2.15,0.12,1.08),metal)
	for x in [-0.82,0.82]:
		box(root,"Leg",Vector3(x,0.39,0),Vector3(0.12,0.76,0.76),dark)
	build_laptop(root,Vector3(0,0.90,-0.08),Color("#42c8ec"))
	build_product_box(root,Vector3(-0.72,0.98,0.26),Vector3(0.32,0.38,0.22),Color("#9a3152"),1)
	build_product_box(root,Vector3(0.72,0.98,0.26),Vector3(0.32,0.38,0.22),Color("#256f8b"),0)
	return root

static func build_entry_mat() -> Node3D:
	var root:=Node3D.new(); root.name="EntryBrandMat_Final"
	box(root,"Mat",Vector3.ZERO,Vector3(2.55,0.035,1.30),mat(Color("#1a2631"),0.86,0.02))
	box(root,"MatBorderFront",Vector3(0,0.025,0.60),Vector3(2.30,0.018,0.045),mat(Color("#161019"),0.52,0.05,Color("#ef365b"),0.58))
	box(root,"MatBorderBack",Vector3(0,0.025,-0.60),Vector3(2.30,0.018,0.045),mat(Color("#101820"),0.52,0.05,Color("#37c1e8"),0.52))
	var red_slash:=box(root,"MatRedSlash",Vector3(-0.78,0.026,0),Vector3(0.28,0.020,0.92),mat(Color("#a82241"),0.74,0.02)); red_slash.rotation_degrees.y=-22
	var blue_slash:=box(root,"MatBlueSlash",Vector3(0.78,0.026,0),Vector3(0.28,0.020,0.92),mat(Color("#247b98"),0.74,0.02)); blue_slash.rotation_degrees.y=-22
	label3d(root,"PCGE",Vector3(0,0.045,0.02),Vector3(-90,0,0),46,Color("#eef5f8"),0.0050)
	return root

static func build_track_spot(accent:Color) -> Node3D:
	var root:=Node3D.new(); root.name="CeilingSpotFixture_Final"
	var dark:=mat(Color("#111820"),0.28,0.52)
	cyl(root,"Housing",Vector3.ZERO,0.17,0.24,dark)
	cyl(root,"Lens",Vector3(0,-0.13,0),0.125,0.025,mat(Color("#d9e6ed"),0.12,0.10,accent,0.72))
	box(root,"Mount",Vector3(0,0.18,0),Vector3(0.22,0.14,0.22),dark)
	return root
