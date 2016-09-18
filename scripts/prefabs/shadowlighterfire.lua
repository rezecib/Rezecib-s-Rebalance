local texture = "fx/torchfire.tex"
local shader = "shaders/vfx_particle.ksh"
local colour_envelope_name = "shadowlighterfirecolourenvelope"
local scale_envelope_name = "shadowlighterfirescaleenvelope"

local assets =
{
	Asset( "IMAGE", texture ),
	Asset( "SHADER", shader ),
}

local max_scale = 2

local function IntColour( r, g, b, a )
	return { r / 255.0, g / 255.0, b / 255.0, a / 255.0 }
end

local init = false
local function InitEnvelope()
	if EnvelopeManager and not init then
		init = true
		EnvelopeManager:AddColourEnvelope(
			colour_envelope_name,
			{	{ 0,	IntColour( 0, 0, 0, 64 ) },
				{ 0.49,	IntColour( 0, 0, 0, 64 ) },
				{ 0.5,	IntColour( 0, 0, 0, 64 ) },
				{ 0.51,	IntColour( 0, 0, 0, 64 ) },
				{ 0.75,	IntColour( 0, 0, 0, 64 ) },
				{ 1,	IntColour( 0, 0, 0, 0 ) },
			} )

		EnvelopeManager:AddVector2Envelope(
			scale_envelope_name,
			{
				{ 0,	{ max_scale * 0.5, max_scale } },
				{ 1,	{ max_scale * 0.5 * 0.5, max_scale * 0.5 } },
			} )
	end
end

local max_lifetime = 0.1
--local ground_height = 0.1

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

	InitEnvelope()

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters( 1 )
	effect:SetRenderResources( 0, texture, shader )
	effect:SetMaxNumParticles( 0, 64 )
	effect:SetMaxLifetime( 0, max_lifetime )
	effect:SetColourEnvelope( 0, colour_envelope_name )
	effect:SetScaleEnvelope( 0, scale_envelope_name )
	effect:SetBlendMode( 0, BLENDMODE.Premultiplied )
	effect:EnableBloomPass( 0, true )
	effect:SetUVFrameSize( 0, 0.25, 1 )
    effect:SetSortOrder( 0, 0 )
    effect:SetSortOffset( 0, 1 )

	-----------------------------------------------------
	local tick_time = TheSim:GetTickTime()

	local desired_particles_per_second = 64
	local particles_per_tick = desired_particles_per_second * tick_time

	local num_particles_to_emit = 1

	local sphere_emitter = CreateSphereEmitter(0.05)

	local function emit_fn()
		local vx, vy, vz = 0.01 * UnitRand(), 0, 0.01 * UnitRand()
		local lifetime = max_lifetime * (0.9 + UnitRand() * 0.1)
		local px, py, pz = sphere_emitter()

		local uv_offset = math.random(0, 3) * 0.25

		effect:AddParticleUV(
			0,
			lifetime,			-- lifetime
			px, py, pz,			-- position
			vx, vy, vz,			-- velocity
			uv_offset, 0		-- uv offset
		)
	end
	
	local function updateFunc()
		while num_particles_to_emit > 1 do
			emit_fn(effect)
			num_particles_to_emit = num_particles_to_emit - 1
		end

		num_particles_to_emit = num_particles_to_emit + particles_per_tick
	end

	EmitterManager:AddEmitter(inst, nil, updateFunc)

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddTag("FX")
    inst.persists = false

    inst.Light:Enable(true)
    inst.Light:SetIntensity(.75)
    inst.Light:SetColour(200 / 255, 150 / 255, 50 / 255)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetRadius(1)

    return inst
end

return Prefab("shadowlighterfire", fn, assets)