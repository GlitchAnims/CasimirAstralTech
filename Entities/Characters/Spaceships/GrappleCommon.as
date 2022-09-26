
const string launchGrappleCommandID = "launch_grapple";
const string grappleSyncCommandID = "grappleinfo_sync";
const string hookSyncCommandID = "hook_sync";

const string hookTargetNetIDString = "hook_target_netid";
const string hookIsAttachedBoolString = "hook_is_attached";

const string hookStuckOffsetString = "hook_stuck_offset";
const string hookStuckOffsetAngleString = "hook_stuck_offset_angle";
const string hookStuckAngleString = "hook_stuck_angle";

const float chainLinkLength = 5.0f;
const u8 grappleMaxTicks = 90;

Random _grapple_r(95444);

void grappleSync( CBlob@ this, u16 hookBlobNetID = 0, f32 chainLength = 0.0f, u16 grappledBlobNetID = 0 )
{
	CBitStream params;
	params.write_u16(hookBlobNetID);
	if (chainLength != 0)
	{
		params.write_f32(chainLength);
		params.write_u16(grappledBlobNetID);
	}
	this.SendCommand(this.getCommandID(grappleSyncCommandID), params);
}

class GrappleInfo
{
	u16 hookBlobNetID;

	f32 chainLength;
	u16 grappledBlobNetID;
};

class ChainInfo
{
	MovingLink@[] movingLinkList;
	MovingBone@[] boneList;
};

class MovingLink
{
	Vec2f pos, prevPos;
	bool locked = false;
}

class MovingBone
{
	MovingLink unit1, unit2;
}

void makeStraightChain(Vec2f fromPos = Vec2f_zero, Vec2f toPos = Vec2f_zero)
{
	if (!isClient()) return;

	Vec2f rayVec = toPos - fromPos;
	int steps = rayVec.getLength();

	Vec2f rayNorm = rayVec;
	rayNorm.Normalize();

	for(int i = 0; i < steps; i += chainLinkLength) //particle loop
	{
		Vec2f pPos = (rayNorm * i);
		pPos += fromPos;

		CParticle@ p = ParticleAnimated("GrappleChain.png", pPos, Vec2f_zero, 45.0f, 0.5f, 2, 0, true);
    	if(p !is null)
    	{
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.bounce = 0;
			p.Z = -100;
			p.timeout = 10;
		}
	}
}

void makeChain(ChainInfo@ chain)
{
	if (!isClient())
	{ return; }

	int movingLinkCount = chain.movingLinkList.get_length();
	for (uint i = 0; i < movingLinkCount; i++)
	{
		MovingLink@ thisMovingLink = chain.movingLinkList[i];

		Vec2f pPos = thisMovingLink.pos;

		CParticle@ p = ParticleAnimated("GrappleChain.png", pPos, Vec2f_zero, 45.0f, 0.5f, 2, 0, true);
    	if(p !is null)
    	{
			p.collides = false;
			p.gravity = Vec2f_zero;
			p.bounce = 0;
			p.Z = -100;
			p.timeout = 10;
		}
	}
}