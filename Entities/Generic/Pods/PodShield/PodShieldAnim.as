// PodShield animations

#include "RunnerAnimCommon.as";
#include "RunnerCommon.as";
#include "KnockedCommon.as";
#include "PixelOffsets.as"
#include "RunnerTextures.as"
#include "CommonFX.as"
#include "ShieldCommon.as"
#include "PodCommon.as"

const string up_fire = "forward_burn";
const string down_fire = "backward_burn";
const string left_fire = "port_burn";
const string right_fire = "starboard_burn";

Random _pod_anim_r(13252);

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
		upFire.ScaleBy(0.5f, 0.5f);
		//upFire.RotateBy(0, Vec2f_zero);
		upFire.SetOffset(Vec2f(7, 0));
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
		downFire.SetOffset(Vec2f(-11, 0));
	}
	if (leftFire !is null)
	{
		Animation@ anim = leftFire.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		leftFire.SetVisible(false);
		leftFire.SetRelativeZ(-1.3f);
		leftFire.ScaleBy(0.5f, 0.5f);
		leftFire.RotateBy(270, Vec2f_zero);
		leftFire.SetOffset(Vec2f(0, 4));
	}
	if (rightFire !is null)
	{
		Animation@ anim = rightFire.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		rightFire.SetVisible(false);
		rightFire.SetRelativeZ(-1.4f);
		rightFire.ScaleBy(0.5f, 0.5f);
		rightFire.RotateBy(90, Vec2f_zero);
		rightFire.SetOffset(Vec2f(0, -4));
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

	PodInfo@ pod;
	if (!blob.get( "podInfo", @pod )) 
	{ return; }

	//set engine burns to correct visibility

	CSpriteLayer@ upFire	= this.getSpriteLayer(up_fire);
	CSpriteLayer@ downFire	= this.getSpriteLayer(down_fire);
	CSpriteLayer@ leftFire	= this.getSpriteLayer(left_fire);
	CSpriteLayer@ rightFire	= this.getSpriteLayer(right_fire);

	bool mainEngine = pod.forward_thrust;
	if (upFire !is null)
	{ upFire.SetVisible(mainEngine); }
	if (downFire !is null)
	{ downFire.SetVisible(pod.backward_thrust); }
	if (leftFire !is null)
	{ leftFire.SetVisible(pod.port_thrust); }
	if (rightFire !is null)
	{ rightFire.SetVisible(pod.starboard_thrust); }
}

/*
void onGib(CSprite@ this)
{
	if (g_kidssafe)
	{
		return;
	}

	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0f;
	const u8 team = blob.getTeamNum();
	CParticle@ Body     = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 0, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Arm      = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 1, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Shield   = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 2, 0, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
	CParticle@ Sword    = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp + 1 , 80), 3, 0, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
}