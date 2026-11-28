extends RefCounted

# Shared real-time material library for the new PC GAME EMPIRE world.
# Procedural surface detail avoids flat primitive shading while keeping memory predictable.

static func painted_metal(color:Color,roughness:float=0.34)->StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=color; m.roughness=roughness; m.metallic=0.62
	return m

static func brushed_metal(color:Color=Color("#687581"))->ShaderMaterial:
	var m:=ShaderMaterial.new(); var s:=Shader.new(); s.code="""
shader_type spatial;
uniform vec4 tint : source_color = vec4(0.41,0.46,0.51,1.0);
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
 float line=sin(UV.y*900.0)*0.018;
 float grain=(hash(floor(UV*420.0))-0.5)*0.035;
 ALBEDO=tint.rgb+vec3(line+grain);
 METALLIC=0.82;
 ROUGHNESS=0.24+abs(line)*1.6;
}
"""; m.shader=s; m.set_shader_parameter("tint",color); return m

static func plastic(color:Color,roughness:float=0.48)->StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=color; m.roughness=roughness; m.metallic=0.04
	return m

static func rubber(color:Color=Color("#10171d"))->StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=color; m.roughness=0.82; m.metallic=0.0
	return m

static func glass(tint:Color=Color(0.14,0.20,0.27,0.34))->StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=tint; m.roughness=0.10; m.metallic=0.05
	m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode=BaseMaterial3D.CULL_DISABLED
	return m

static func emissive(base:Color,glow:Color,energy:float=2.0,metallic:float=0.18)->StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=base; m.roughness=0.22; m.metallic=metallic
	m.emission_enabled=true; m.emission=glow; m.emission_energy_multiplier=energy
	return m

static func floor_material()->ShaderMaterial:
	var m:=ShaderMaterial.new(); var s:=Shader.new(); s.code="""
shader_type spatial;
float h(vec2 p){return fract(sin(dot(p,vec2(41.31,289.17)))*43758.5453);}
void fragment(){
 vec2 tile=UV*18.0;
 vec2 f=fract(tile);
 float seam=max(step(0.975,f.x),step(0.975,f.y));
 float micro=(h(floor(UV*460.0))-0.5)*0.045;
 vec3 base=vec3(0.085,0.105,0.13)+vec3(micro);
 ALBEDO=mix(base,vec3(0.025,0.032,0.041),seam*0.72);
 ROUGHNESS=0.48+micro*0.7;
 METALLIC=0.22;
}
"""; m.shader=s; return m

static func lab_floor_material()->ShaderMaterial:
	var m:=ShaderMaterial.new(); var s:=Shader.new(); s.code="""
shader_type spatial;
float h(vec2 p){return fract(sin(dot(p,vec2(92.21,17.73)))*34918.113);}
void fragment(){
 vec2 t=UV*13.0; vec2 f=fract(t);
 float seam=max(step(0.97,f.x),step(0.97,f.y));
 float speck=step(0.985,h(floor(UV*360.0)))*0.10;
 vec3 base=vec3(0.060,0.082,0.096)+speck*vec3(0.3,0.4,0.44);
 ALBEDO=mix(base,vec3(0.018,0.025,0.030),seam*0.76);
 ROUGHNESS=0.62; METALLIC=0.10;
}
"""; m.shader=s; return m

static func wall_panel(color:Color=Color("#171f28"))->ShaderMaterial:
	var m:=ShaderMaterial.new(); var s:=Shader.new(); s.code="""
shader_type spatial;
uniform vec4 tint : source_color = vec4(0.09,0.12,0.15,1.0);
float h(vec2 p){return fract(sin(dot(p,vec2(13.77,71.29)))*12741.73);}
void fragment(){
 float grain=(h(floor(UV*260.0))-0.5)*0.028;
 float groove=step(0.985,fract(UV.x*8.0))*0.32;
 ALBEDO=max(tint.rgb+grain-vec3(groove),vec3(0.01));
 ROUGHNESS=0.54; METALLIC=0.16;
}
"""; m.shader=s; m.set_shader_parameter("tint",color); return m

static func composite_wood(color:Color=Color("#414953"))->ShaderMaterial:
	var m:=ShaderMaterial.new(); var s:=Shader.new(); s.code="""
shader_type spatial;
uniform vec4 tint : source_color = vec4(0.25,0.28,0.32,1.0);
float h(float x){return fract(sin(x*91.17)*15143.97);}
void fragment(){
 float grain=sin(UV.x*120.0+sin(UV.y*13.0)*2.0)*0.032 + (h(floor(UV.y*90.0))-0.5)*0.018;
 ALBEDO=tint.rgb+vec3(grain);
 ROUGHNESS=0.46; METALLIC=0.08;
}
"""; m.shader=s; m.set_shader_parameter("tint",color); return m

static func screen(accent:Color)->ShaderMaterial:
	var m:=ShaderMaterial.new(); var s:=Shader.new(); s.code="""
shader_type spatial;
uniform vec4 accent : source_color = vec4(0.2,0.75,0.95,1.0);
uniform float pulse=1.0;
void fragment(){
 vec2 uv=UV;
 float line=smoothstep(0.48,0.50,abs(fract(uv.y*18.0)-0.5))*0.045;
 float vign=1.0-smoothstep(0.25,0.72,distance(uv,vec2(0.5)));
 vec3 col=mix(vec3(0.018,0.032,0.045),accent.rgb*0.44,vign)+line*accent.rgb;
 ALBEDO=col*0.35;
 EMISSION=col*(1.2+0.7*pulse);
 ROUGHNESS=0.18; METALLIC=0.06;
}
"""; m.shader=s; m.set_shader_parameter("accent",accent); return m
