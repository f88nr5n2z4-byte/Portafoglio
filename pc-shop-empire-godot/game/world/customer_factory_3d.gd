extends RefCounted

static func spawn_customer(parent:Node3D,customer_script:Script,visual_script:Script,n:String,start:Vector3,route:Array,body:Color,accent:Color,skin:Color,style:String)->CharacterBody3D:
	var actor:CharacterBody3D=customer_script.new()
	actor.name=n; actor.position=start
	var collision:=CollisionShape3D.new(); var capsule:=CapsuleShape3D.new(); capsule.radius=0.31; capsule.height=1.78; collision.shape=capsule; collision.position.y=0.89; actor.add_child(collision)
	var visual=visual_script.new(); visual.name="CustomerVisual"; visual.configure(body,accent,skin,style); actor.add_child(visual)
	parent.add_child(actor)
	actor.set_route(route)
	return actor
