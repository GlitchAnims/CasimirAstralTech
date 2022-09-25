
#include "CommonFX.as"

const string alertCircleName = "alert_circle";

const int[] alertFrames1 = {0, 1, 2, 3};
const int[] alertFrames2 = {3};

Random _pod_anim_r(13252);

void onInit(CSprite@ this)
{
	LoadSprites(this);
}

void LoadSprites(CSprite@ this)
{
	CBlob@ thisBlob = this.getBlob();
	if (thisBlob == null) return;
	int teamNum = thisBlob.getTeamNum();

	this.RemoveSpriteLayer(alertCircleName);
	CSpriteLayer@ alertCircle = this.addSpriteLayer(alertCircleName, "Flash1.png", 128, 128, teamNum, teamNum);
	if (alertCircle !is null)
	{
		Animation@ anim = alertCircle.addAnimation("default", 1, true);
		anim.AddFrames(alertFrames1);
		Animation@ anim2 = alertCircle.addAnimation("tripped", 30, true);
		anim2.AddFrames(alertFrames2);
		alertCircle.SetVisible(false);
		alertCircle.SetRelativeZ(-0.5f);
		//alertCircle.ScaleBy(3.0f, 3.0f);
		//alertCircle.RotateBy(0, Vec2f_zero);
		alertCircle.SetOffset(Vec2f(0, 0));
		alertCircle.setRenderStyle(RenderStyle::light);
		alertCircle.SetLighting(true);
	}
}

void onTick(CSprite@ this)
{
	CBlob@ thisBlob = this.getBlob();
	if (thisBlob == null) return;

	Vec2f blobPos = thisBlob.getPosition();
	Vec2f blobVel = thisBlob.getVelocity();
	f32 blobAngle = thisBlob.getAngleDegrees();
	blobAngle = (blobAngle+360.0f) % 360;
	int teamNum = thisBlob.getTeamNum();

	CSpriteLayer@ alertCircle = this.getSpriteLayer(alertCircleName);

	if (alertCircle !is null)
	{ 
		s8 ordinanceState = thisBlob.get_s8("ordinance_state");
		bool isActive = ordinanceState > 0;

		if (isActive)
		{
			alertCircle.SetVisible(true);

			string animationName = ordinanceState == 2 ? "tripped" : "default";
			alertCircle.SetAnimation(animationName);
		}

		alertCircle.ResetTransform();
		alertCircle.RotateBy(-blobAngle, Vec2f_zero);
	}
}