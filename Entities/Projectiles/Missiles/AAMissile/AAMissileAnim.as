// Fighter animations

#include "MissileCommon.as"
#include "RunnerAnimCommon.as"
#include "RunnerCommon.as"
#include "KnockedCommon.as"
#include "PixelOffsets.as"
#include "RunnerTextures.as"
#include "CommonFX.as"

const string up_fire = "forward_burn";
const string down_fire = "backward_burn";
const string left_fire = "port_burn";
const string right_fire = "starboard_burn";

Random _fighter_anim_r(14861);

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
	// add engine burns
	this.RemoveSpriteLayer(up_fire);
	CSpriteLayer@ upFire = this.addSpriteLayer(up_fire, "ThrustFlash.png", 27, 27);
	if (upFire !is null)
	{
		Animation@ anim = upFire.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		upFire.SetVisible(false);
		upFire.SetRelativeZ(-1.1f);
		upFire.ScaleBy(0.5f, 0.5f);
		upFire.SetOffset(Vec2f(4, 0));
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

	MissileInfo@ missile;
	if (!blob.get( "missileInfo", @missile )) 
	{ return; }
	
	//set engine burns to correct visibility

	CSpriteLayer@ upFire	= this.getSpriteLayer(up_fire);

	bool mainEngine = missile.forward_thrust;
	if (upFire !is null)
	{ upFire.SetVisible(mainEngine); }


	if (mainEngine)
	{
		Vec2f engineOffset = Vec2f(-4.0f, 0);
		engineOffset.RotateByDegrees(blobAngle);
		Vec2f trailPos = blobPos + engineOffset;

		Vec2f trailNorm = Vec2f(-1.0f, 0);
		trailNorm.RotateByDegrees(blobAngle);

		u32 gameTime = getGameTime();

		//f32 trailSwing = Maths::Sin(gameTime * 0.1f) + 1.0f;
		//trailSwing *= 0.5f;
		f32 trailSwing = Maths::Sin(gameTime * 0.1f);

		f32 swingMaxAngle = 30.0f * trailSwing;

		u16 particleNum = 3; //loop will do this + 1

		int teamNum = blob.getTeamNum();
		SColor color = getTeamColorWW(teamNum);

		for(int i = 0; i <= particleNum; i++)
	    {
			u8 alpha = 200.0f + (55.0f * _fighter_anim_r.NextFloat()); //randomize alpha
			color.setAlpha(alpha);

			f32 pRatio = float(i) / float(particleNum);
			f32 pAngle = (pRatio*2.0f) - 1.0f;

			Vec2f pVel = trailNorm;
			pVel.RotateByDegrees(swingMaxAngle*pAngle);
			pVel *= 5.0f - Maths::Abs(pAngle);

			pVel += blobVel;

	        CParticle@ p = ParticlePixelUnlimited(trailPos, pVel, color, true);
	        if(p !is null)
	        {
	   	        p.collides = false;
	   	        p.gravity = Vec2f_zero;
	            p.bounce = 0;
	            p.Z = 7;
	            p.timeout = 15.0f + (7.5f * _fighter_anim_r.NextFloat());
				p.setRenderStyle(RenderStyle::light);
	    	}
		}
	}

}