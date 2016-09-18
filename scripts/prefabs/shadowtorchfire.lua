local smoke_texture = "fx/smoke.tex"
local texture = "fx/torchfire.tex"
local shader = "shaders/vfx_particle.ksh"

local colour_envelope_name_smoke = "shadowfiresmokecolourenvelope"
local scale_envelope_name_smoke = "shadowfiresmokescaleenvelope"
local colour_envelope_name = "shadowfirecolourenvelope"
local scale_envelope_name = "shadowfirescaleenvelope"

local assets =
{
    Asset( "IMAGE", texture ),
    Asset( "SHADER", shader ),
}


local function IntColour( r, g, b, a )
    return { r / 255.0, g / 255.0, b / 255.0, a / 255.0 }
end

local init = false
local function InitEnvelope()
    if EnvelopeManager and not init then
        init = true
        EnvelopeManager:AddColourEnvelope(
            colour_envelope_name_smoke,
            {
				{ 0,    IntColour( 35, 32, 30, 0 ) },
				{ .3,   IntColour( 35, 32, 30, 100 ) },
				{ .55,  IntColour( 30, 30, 30, 28 ) },
                { 1,    IntColour( 30, 30, 30, 0 ) },
            } )
			
        local smoke_max_scale = 1.25
        EnvelopeManager:AddVector2Envelope(
            scale_envelope_name_smoke,
            {
                { 0,    { smoke_max_scale * 0.4, smoke_max_scale * 0.4} },
				{ .50,  { smoke_max_scale * 0.6, smoke_max_scale * 0.6} },
				{ .65,  { smoke_max_scale * 0.9, smoke_max_scale * 0.9} },
                { 1,    { smoke_max_scale, smoke_max_scale} },
            } )
            
        EnvelopeManager:AddColourEnvelope(
            colour_envelope_name,
            {   { 0,    IntColour( 0, 0, 0, 64 ) },
                { 0.49, IntColour( 0, 0, 0, 64 ) },
                { 0.5,  IntColour( 0, 0, 0, 64 ) },
                { 0.51, IntColour( 0, 0, 0, 64 ) },
                { 0.75, IntColour( 0, 0, 0, 64 ) },
                { 1,    IntColour( 0, 0, 0, 0 ) },
            } )
			
		local max_scale = 3
        EnvelopeManager:AddVector2Envelope(
            scale_envelope_name,
            {
                { 0,    { max_scale * 0.5, max_scale } },
                { 1,    { max_scale * 0.5 * 0.5, max_scale * 0.5 } },
            } )
    end
end

local fire_max_lifetime = 0.3
local smoke_max_lifetime = 0.7


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    InitEnvelope()

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters( 2 )
    
    --SMOKE
    effect:SetRenderResources( 0, smoke_texture, shader )
    effect:SetMaxNumParticles( 0, 64 )
    effect:SetMaxLifetime( 0, smoke_max_lifetime )
    effect:SetColourEnvelope( 0, colour_envelope_name_smoke )
    effect:SetScaleEnvelope( 0, scale_envelope_name_smoke )
    effect:SetBlendMode( 0, BLENDMODE.Premultiplied )
    effect:EnableBloomPass( 0, true )
    effect:SetUVFrameSize( 0, 0.25, 1 )
    effect:SetSortOrder( 0, 1 )
    effect:SetRadius( 0, 2 ) --only needed on a single emitter
    
    --FIRE
    effect:SetRenderResources( 1, texture, shader )
    effect:SetMaxNumParticles( 1, 64 )
    effect:SetMaxLifetime( 1, fire_max_lifetime )
    effect:SetColourEnvelope( 1, colour_envelope_name )
    effect:SetScaleEnvelope( 1, scale_envelope_name )
    effect:SetBlendMode( 1, BLENDMODE.Premultiplied )
    effect:EnableBloomPass( 1, true )
    effect:SetUVFrameSize( 1, 0.25, 1 )
    effect:SetSortOrder( 1, 2 )


	inst.fx_offset = -110
	
    -----------------------------------------------------
    local tick_time = TheSim:GetTickTime()

    local smoke_desired_pps = 80
    local smoke_particles_per_tick = smoke_desired_pps * tick_time
    local smoke_num_particles_to_emit = -50 --start delay
	
    local fire_desired_pps = 40
	local fire_particles_per_tick = fire_desired_pps * tick_time
    local fire_num_particles_to_emit = 1
    
    local sphere_emitter = CreateSphereEmitter(0.05)

    local function emit_smoke_fn()
		--SMOKE
        local vx, vy, vz = 0.01 * UnitRand(), 0, 0.01 * UnitRand()
        vy = vy + 0.05
        local lifetime = smoke_max_lifetime * (0.9 + UnitRand() * 0.1)
        local px, py, pz = sphere_emitter()

		local uv_offset = math.random(0, 3) * 0.25

        effect:AddParticleUV(
            0,
            lifetime,           -- lifetime
            px, py, pz,         -- position
            vx, vy, vz,         -- velocity
            uv_offset, 0        -- uv offset
        )      
    end
        
    local function emit_fire_fn()            
        --FIRE
        local vx, vy, vz = 0.01 * UnitRand(), 0, 0.01 * UnitRand()
        local lifetime = fire_max_lifetime * (0.9 + UnitRand() * 0.1)
		local px, py, pz = sphere_emitter()

        local uv_offset = math.random(0, 3) * 0.25

        effect:AddParticleUV(
			1,
            lifetime,           -- lifetime
            px, py, pz,         -- position
            vx, vy, vz,         -- velocity
            uv_offset, 0        -- uv offset
        )
    end
    
    local function updateFunc()
		--SMOKE
        while smoke_num_particles_to_emit > 1 do
            emit_smoke_fn(effect)
            smoke_num_particles_to_emit = smoke_num_particles_to_emit - 1
        end
        smoke_num_particles_to_emit = smoke_num_particles_to_emit + smoke_particles_per_tick
                
        --FIRE
        while fire_num_particles_to_emit > 1 do
            emit_fire_fn(effect)
            fire_num_particles_to_emit = fire_num_particles_to_emit - 1
        end
        fire_num_particles_to_emit = fire_num_particles_to_emit + fire_particles_per_tick
	end
    EmitterManager:AddEmitter(inst, nil, updateFunc)

    inst:AddTag("FX")
    inst:AddTag("playerlight")

    inst.Light:Enable(true)
    inst.Light:SetIntensity(.75)
    inst.Light:SetColour(197 / 255, 197 / 255, 50 / 255)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetRadius(2)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("shadowtorchfire", fn, assets)
