// Interceptor animations

#include "SmallshipCommon.as";
#include "RunnerAnimCommon.as";
#include "RunnerCommon.as";
#include "KnockedCommon.as";
#include "PixelOffsets.as"
#include "RunnerTextures.as"
#include "CommonFX.as"
#include "ShieldCommon.as"

const string up_fire = "forward_burn";
const string down_fire = "backward_burn";
const string left_fire = "port_burn";
const string right_fire = "starboard_burn";

Random _interceptor_anim_r(04444);

void onInit(CSprite@ this)
{
	LoadSprites(this);
}

void onPlayerInfoChanged(CSprite@ this)
{
	LoadSprites(this);
}

void LoadSprites(CSprite@ this)
{

	// add shiny
	/*
	this.RemoveSpriteLayer(shiny_layer);
	CSpriteLayer@ shiny = this.addSpriteLayer(shiny_layer, "AnimeShiny.png", 16, 16);
	if (shiny !is null)
	{
		Animation@ anim = shiny.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		shiny.SetVisible(false);
		shiny.SetRelativeZ(1.0f);
	}*/

	// add engine burns
	this.RemoveSpriteLayer(up_fire);
	this.RemoveSpriteLayer(down_fire);
	this.RemoveSpriteLayer(left_fire);
	this.RemoveSpriteLayer(right_fire);
	CSpriteLayer@ upFire = this.addSpriteLayer(up_fire, "ThrustFlash.png", 27, 27);
	CSpriteLayer@ downFire = this.addSpriteLayer(down_fire, "ThrustFlash.png", 27, 27);
	CSpriteLayer@ leftFire = this.addSpriteLayer(left_fire, "ThrustFlash.png", 27, 27);
	CSpriteLayer@ rightFire = this.addSpriteLayer(right_fire, "ThrustFlash.png", 27, 27);
	if (upFire !is null)
	{
		Animation@ anim = upFire.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		upFire.SetVisible(false);
		upFire.SetRelativeZ(-1.1f);
		//upFire.RotateBy(0, Vec2f_zero);
		upFire.SetOffset(Vec2f(6, 0));
	}
	if (downFire !is null)
	{
		Animation@ anim = downFire.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		downFire.SetVisible(false);
		downFire.SetRelativeZ(-1.2f);
		downFire.ScaleBy(0.5f, 0.5f);
		downFire.RotateBy(180, Vec2f_zero);
		downFire.SetOffset(Vec2f(-7, 0));
	}
	if (leftFire !is null)
	{
		Animation@ anim = leftFire.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		leftFire.SetVisible(false);
		leftFire.SetRelativeZ(-1.3f);
		leftFire.ScaleBy(0.3f, 0.3f);
		leftFire.RotateBy(270, Vec2f_zero);
		leftFire.SetOffset(Vec2f(3, 7));
	}
	if (rightFire !is null)
	{
		Animation@ anim = rightFire.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		rightFire.SetVisible(false);
		rightFire.SetRelativeZ(-1.4f);
		rightFire.ScaleBy(0.3f, 0.3f);
		rightFire.RotateBy(90, Vec2f_zero);
		rightFire.SetOffset(Vec2f(3, -7));
	}
	
}

void onTick(CSprite@ this)
{
	// store some vars for ease and speed
	CBlob@ blob = this.getBlob();
	if (blob == null)
	{ return; }

	Vec2f blobPos = blob.getPosition();
	Vec2f blobVel = blob.getVelocity();
	f32 blobAngle = blob.getAngleDegrees();
	blobAngle = (blobAngle+360.0f) % 360;
	Vec2f aimpos;

	/*KnightInfo@ knight;
	if (!blob.get("knightInfo", @knight))
	{
		return;
	}*/

	SmallshipInfo@ ship;
	if (!blob.get( "shipInfo", @ship )) 
	{ return; }


	//set engine burns to correct visibility

	CSpriteLayer@ upFire	= this.getSpriteLayer(up_fire);
	CSpriteLayer@ downFire	= this.getSpriteLayer(down_fire);
	CSpriteLayer@ leftFire	= this.getSpriteLayer(left_fire);
	CSpriteLayer@ rightFire	= this.getSpriteLayer(right_fire);

	bool mainEngine = ship.forward_thrust;
	if (upFire !is null)
	{ upFire.SetVisible(mainEngine); }
	if (downFire !is null)
	{ downFire.SetVisible(ship.backward_thrust); }
	if (leftFire !is null)
	{ leftFire.SetVisible(ship.port_thrust); }
	if (rightFire !is null)
	{ rightFire.SetVisible(ship.starboard_thrust); }

	if (mainEngine)
	{
		Vec2f engineOffset = Vec2f(-6.0f, 0);
		engineOffset.RotateByDegrees(blobAngle);
		Vec2f trailPos = blobPos + engineOffset;

		Vec2f trailNorm = Vec2f(-1.0f, 0);
		trailNorm.RotateByDegrees(blobAngle);

		u32 gameTime = getGameTime();

		//f32 trailSwing = Maths::Sin(gameTime * 0.1f) + 1.0f;
		//trailSwing *= 0.5f;
		f32 trailSwing = Maths::Sin(gameTime * 0.1f);

		f32 swingMaxAngle = 30.0f * trailSwing;

		u16 particleNum = 9; //loop will do this + 1

		int teamNum = blob.getTeamNum();
		SColor color = getTeamColorWW(teamNum);

		for(int i = 0; i <= particleNum; i++)
	    {
			u8 alpha = 200.0f + (55.0f * _interceptor_anim_r.NextFloat()); //randomize alpha
			color.setAlpha(alpha);

			f32 pRatio = float(i) / float(particleNum);
			f32 pAngle = (pRatio*2.0f) - 1.0f;

			Vec2f pVel = trailNorm * 1.5f;
			pVel.RotateByDegrees(swingMaxAngle*pAngle);
			pVel *= 3.0f - Maths::Abs(pAngle);

			pVel += blobVel;

	        CParticle@ p = ParticlePixelUnlimited(trailPos, pVel, color, true);
	        if(p !is null)
	        {
	   	        p.collides = false;
	   	        p.gravity = Vec2f_zero;
	            p.bounce = 0;
	            p.Z = 7;
	            p.timeout = 30.0f + (15.0f * _interceptor_anim_r.NextFloat());
				p.setRenderStyle(RenderStyle::light);
	    	}
		}
	}
}