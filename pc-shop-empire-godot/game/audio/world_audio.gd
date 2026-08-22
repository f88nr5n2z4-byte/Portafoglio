extends RefCounted

# Small synthesized interaction sounds used by the real-world slice.
# Keeps M0 self-contained until the full authored audio library lands in the content milestone.

static func door_stream()->AudioStreamWAV:
	return _tone_stream(0.34,110.0,58.0,0.34,true)

static func interact_stream()->AudioStreamWAV:
	return _tone_stream(0.11,520.0,760.0,0.20,false)

static func success_stream()->AudioStreamWAV:
	return _tone_stream(0.16,420.0,690.0,0.18,false)

static func _tone_stream(duration:float,start_hz:float,end_hz:float,gain:float,add_noise:bool)->AudioStreamWAV:
	var rate:=22050
	var count:=int(duration*rate)
	var bytes:=PackedByteArray(); bytes.resize(count*2)
	var phase:=0.0
	for i in range(count):
		var t:=float(i)/float(max(1,count-1))
		var hz:=lerp(start_hz,end_hz,t)
		phase += TAU*hz/float(rate)
		var env:=sin(PI*clamp(t,0.0,1.0))
		var sample:=sin(phase)*gain*env
		if add_noise:
			var hash_value:=fmod(sin(float(i)*12.9898)*43758.5453,1.0)
			sample += (hash_value-0.5)*0.08*env
		sample=clamp(sample,-1.0,1.0)
		bytes.encode_s16(i*2,int(sample*32767.0))
	var wav:=AudioStreamWAV.new()
	wav.format=AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate=rate
	wav.stereo=false
	wav.data=bytes
	return wav
