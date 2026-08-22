extends RefCounted

const Materials = preload("res://game/art/world_materials.gd")
const ShopAssets = preload("res://game/art/modular_shop_assets.gd")
const LegacyCleanup = preload("res://game/art/legacy_visual_cleanup.gd")

static func build() -> Node3D:
	var root:=LegacyCleanup.new(); root.name="WorldSurfaceFinish_Final"
	# Thin finish meshes sit above/inside the physical blockout surfaces. Physics remains unchanged.
	ShopAssets.box(root,"ShopFloorFinish",Vector3(0,0.012,0),Vector3(17.88,0.024,15.88),Materials.floor_material())
	ShopAssets.box(root,"LabFloorFinish",Vector3(13.5,0.014,-1.0),Vector3(8.88,0.026,11.88),Materials.lab_floor_material())
	# Shop interior wall panels.
	ShopAssets.box(root,"ShopBackFinish",Vector3(0,1.58,-7.805),Vector3(17.72,3.02,0.025),Materials.wall_panel(Color("#18222c")))
	ShopAssets.box(root,"ShopLeftFinish",Vector3(-8.805,1.58,0),Vector3(0.025,3.02,15.72),Materials.wall_panel(Color("#161f29")))
	ShopAssets.box(root,"ShopFrontLeftFinish",Vector3(-5.4,1.58,7.805),Vector3(7.0,3.02,0.025),Materials.wall_panel(Color("#172029")))
	ShopAssets.box(root,"ShopFrontRightFinish",Vector3(5.4,1.58,7.805),Vector3(7.0,3.02,0.025),Materials.wall_panel(Color("#172029")))
	ShopAssets.box(root,"PartitionAFinish",Vector3(8.805,1.58,-5.3),Vector3(0.025,3.02,5.15),Materials.wall_panel(Color("#19242e")))
	ShopAssets.box(root,"PartitionBFinish",Vector3(8.805,1.58,3.2),Vector3(0.025,3.02,9.35),Materials.wall_panel(Color("#19242e")))
	# Lab walls use a cooler, more technical finish.
	ShopAssets.box(root,"LabBackFinish",Vector3(13.5,1.58,-6.805),Vector3(8.72,3.02,0.025),Materials.wall_panel(Color("#15222b")))
	ShopAssets.box(root,"LabRightFinish",Vector3(17.805,1.58,-1.0),Vector3(0.025,3.02,11.72),Materials.wall_panel(Color("#14202a")))
	ShopAssets.box(root,"LabFrontFinish",Vector3(13.5,1.58,4.805),Vector3(8.72,3.02,0.025),Materials.wall_panel(Color("#16232c")))
	# Brushed-metal kick plates / trims create material separation around the rooms.
	var trim:=Materials.brushed_metal(Color("#586572"))
	ShopAssets.box(root,"BackBaseTrim",Vector3(0,0.13,-7.75),Vector3(17.65,0.16,0.08),trim)
	ShopAssets.box(root,"LeftBaseTrim",Vector3(-8.75,0.13,0),Vector3(0.08,0.16,15.65),trim)
	ShopAssets.box(root,"LabBackBaseTrim",Vector3(13.5,0.13,-6.75),Vector3(8.65,0.16,0.08),trim)
	ShopAssets.box(root,"LabRightBaseTrim",Vector3(17.75,0.13,-1),Vector3(0.08,0.16,11.65),trim)
	return root
