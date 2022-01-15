// Fighter animations

#include "OrdinanceCommon.as"
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

Random _flare_anim_r(14861);

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
	CSpriteLayer@ upFire = this.addSpriteLayer(up_fire, "Flare_Flare.png", 16, 16);
	if (upFire !is null)
	{
		Animation@ anim = upFire.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3, 4, 5};
		anim.AddFrames(frames);
		upFire.SetVisible(false);
		upFire.SetRelativeZ(-1.1f);
		upFire.ScaleBy(0.8f, 0.8f);
		upFire.SetOffset(Vec2f(0, 0));
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
        Vec2f vel(_flare_anim_r.NextFloat() * 6.0f, 0);
        vel.RotateBy(_flare_anim_r.NextFloat() * 360.0f);

        CParticle@ p = ParticleAnimated("Flare_Flare.png", 
									blobPos, 
									vel + blobVel, 
									float(XORRandom(360)), //rotation
									0.5f, //scale
									2, //animation speed
									0.0f, 
									false );
        if(p != null)  //bail if we stop getting particles
		{
			p.collides = false;
			p.damping = 0.85f;
			p.Z = -10.0f;
			p.lighting = false;
		}
	}

}