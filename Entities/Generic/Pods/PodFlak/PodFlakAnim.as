// PodFlak animations

#include "CommonFX.as"
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
		downFire.ScaleBy(0.3f, 0.3f);
		//upFire.RotateBy(0, Vec2f_zero);
		upFire.SetOffset(Vec2f(7.5f, 0));
	}
	if (downFire !is null)
	{
		Animation@ anim = downFire.addAnimation("default", 2, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		downFire.SetVisible(false);
		downFire.SetRelativeZ(-1.2f);
		downFire.ScaleBy(0.3f, 0.3f);
		downFire.RotateBy(180, Vec2f_zero);
		downFire.SetOffset(Vec2f(-7.5f, 0));
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
		leftFire.SetOffset(Vec2f(0, 7.5f));
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
		rightFire.SetOffset(Vec2f(0, -7.5f));
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