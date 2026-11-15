extends RefCounted

const Materials = preload("res://game/art/world_materials.gd")
const ShopAssets = preload("res://game/art/modular_shop_assets.gd")
const LegacyCleanup = preload("res://game/art/legacy_visual_cleanup.gd")

static func build() -> Node3D:
	var root:=LegacyCleanup.new(); root.name="WorldSurfaceFinish_Final"
	# A real mesh plinth replaces the empty blue void and presents the store as a premium diorama.
	# It is intentionally below the playable floors and has no collision.
	ShopAssets.box(root,"DioramaFoundation",Vector3(4.5,-0.42,0),Vector3(31.0,0.42,22.0),Materials.painted_metal(Color("#090f17"),0.50))
	ShopAssets.box(root,"DioramaTop",Vector3(4.5,-0.19,0),Vector3(30.55,0.045,21.55),Materials.wall_panel(Color("#101a25")))
	ShopAssets.box(root,"EntranceApron",Vector3(0,-0.125,9.05),Vector3(5.4,0.08,2.0),Materials.brushed_metal(Color("#273746")))
	# Thin finish meshes sit above/inside the physical blockout surfaces. Physics remains unchanged.
	ShopAssets.box(root,"ShopFloorFinish",Vector3(0,0.012,0),Vector3(17.88,0.024,15.88),Materials.floor_material())
	ShopAssets.box(root,"LabFloorFinish",Vector3(13.5,0.014,-1.0),Vector3(8.88,0.026,11.88),Materials.lab_floor_material())
	# Shop interior wall panels.
	ShopAssets.box(root,"ShopBackFinish",Vector3(0,1.58,-7.805),Vector3(17.72,3.02,0.025),Materials.wall_panel(Color("#18222c")))
	ShopAssets.box(root,"ShopLeftFinish",Vector3(-8.805,1.58,0),Vector3(0.025,3.02,15.72),Materials.wall_panel(Color("#161f29")))
	# Camera-facing walls use a deliberate cutaway profile; hidden full-height collision remains active.
	var cut_height:=0.86
	ShopAssets.box(root,"ShopFrontLeftCutaway",Vector3(-5.4,cut_height*0.5,7.805),Vector3(7.0,cut_height,0.18),Materials.wall_panel(Color("#172029")))
	ShopAssets.box(root,"ShopFrontRightCutaway",Vector3(5.4,cut_height*0.5,7.805),Vector3(7.0,cut_height,0.18),Materials.wall_panel(Color("#172029")))
	ShopAssets.box(root,"EntranceLeftCutaway",Vector3(-2.2,cut_height*0.5,7.78),Vector3(1.4,cut_height,0.34),Materials.wall_panel(Color("#202d39")))
	ShopAssets.box(root,"EntranceRightCutaway",Vector3(2.2,cut_height*0.5,7.78),Vector3(1.4,cut_height,0.34),Materials.wall_panel(Color("#202d39")))
	ShopAssets.box(root,"PartitionACutaway",Vector3(8.805,cut_height*0.5,-5.3),Vector3(0.18,cut_height,5.15),Materials.wall_panel(Color("#19242e")))
	ShopAssets.box(root,"PartitionBCutaway",Vector3(8.805,cut_height*0.5,3.2),Vector3(0.18,cut_height,9.35),Materials.wall_panel(Color("#19242e")))
	# Lab walls use a cooler, more technical finish.
	ShopAssets.box(root,"LabBackFinish",Vector3(13.5,1.58,-6.805),Vector3(8.72,3.02,0.025),Materials.wall_panel(Color("#15222b")))
	ShopAssets.box(root,"LabRightCutaway",Vector3(17.805,cut_height*0.5,-1.0),Vector3(0.18,cut_height,11.72),Materials.wall_panel(Color("#14202a")))
	ShopAssets.box(root,"LabFrontCutaway",Vector3(13.5,cut_height*0.5,4.805),Vector3(8.72,cut_height,0.18),Materials.wall_panel(Color("#16232c")))
	# Brushed-metal kick plates / trims create material separation around the rooms.
	var trim:=Materials.brushed_metal(Color("#586572"))
	ShopAssets.box(root,"BackBaseTrim",Vector3(0,0.13,-7.75),Vector3(17.65,0.16,0.08),trim)
	ShopAssets.box(root,"LeftBaseTrim",Vector3(-8.75,0.13,0),Vector3(0.08,0.16,15.65),trim)
	ShopAssets.box(root,"LabBackBaseTrim",Vector3(13.5,0.13,-6.75),Vector3(8.65,0.16,0.08),trim)
	ShopAssets.box(root,"LabRightBaseTrim",Vector3(17.75,0.13,-1),Vector3(0.08,0.16,11.65),trim)
	# Brushed caps make the cutaway walls read as finished architecture instead of hidden blockout.
	ShopAssets.box(root,"ShopFrontLeftCap",Vector3(-5.4,cut_height+0.045,7.79),Vector3(7.08,0.09,0.32),trim)
	ShopAssets.box(root,"ShopFrontRightCap",Vector3(5.4,cut_height+0.045,7.79),Vector3(7.08,0.09,0.32),trim)
	ShopAssets.box(root,"PartitionACap",Vector3(8.79,cut_height+0.045,-5.3),Vector3(0.32,0.09,5.24),trim)
	ShopAssets.box(root,"PartitionBCap",Vector3(8.79,cut_height+0.045,3.2),Vector3(0.32,0.09,9.44),trim)
	ShopAssets.box(root,"LabRightCap",Vector3(17.79,cut_height+0.045,-1.0),Vector3(0.32,0.09,11.82),trim)
	ShopAssets.box(root,"LabFrontCap",Vector3(13.5,cut_height+0.045,4.79),Vector3(8.82,0.09,0.32),trim)
	return root
