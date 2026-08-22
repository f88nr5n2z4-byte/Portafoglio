extends RefCounted

static func spawn_customer(parent:Node3D,customer_script:Script,visual_script:Script,n:String,start:Vector3,route:Array,body:Color,accent:Color,skin:Color,style:String)->CharacterBody3D:
	var actor:CharacterBody3D=customer_script.new()
	actor.name=n; actor.position=start
	var collision:=CollisionShape3D.new(); var capsule:=CapsuleShape3D.new(); capsule.radius=0.31; capsule.height=1.78; collision.shape=capsule; collision.position.y=0.89; actor.add_child(collision)
	var visual=visual_script.new(); visual.name="CustomerVisual"; visual.configure(body,accent,skin,style); actor.add_child(visual)
	parent.add_child(actor)
	actor.set_route(route)
	return actor

static func spawn_ambient_set(parent:Node3D,customer_script:Script,visual_script:Script)->Array[CharacterBody3D]:
	var actors:Array[CharacterBody3D]=[]
	actors.append(spawn_customer(parent,customer_script,visual_script,"Customer_Gamer",Vector3(-4.4,0.02,6.7),[Vector3(-4.4,0.02,4.9),Vector3(-3.0,0.02,3.2),Vector3(-5.8,0.02,-1.7)],Color("#6a3fc0"),Color("#1d2631"),Color("#c78f6e"),"gamer"))
	actors.append(spawn_customer(parent,customer_script,visual_script,"Customer_CasualWoman",Vector3(4.5,0.02,6.6),[Vector3(4.1,0.02,4.7),Vector3(2.8,0.02,3.4),Vector3(6.15,0.02,-3.7)],Color("#b54e78"),Color("#25303b"),Color("#d3a17e"),"female_casual"))
	actors.append(spawn_customer(parent,customer_script,visual_script,"Customer_Professional",Vector3(7.2,0.02,6.0),[Vector3(6.0,0.02,4.7),Vector3(5.5,0.02,2.4),Vector3(5.7,0.02,0.2)],Color("#344b63"),Color("#202832"),Color("#b98465"),"professional"))
	return actors
