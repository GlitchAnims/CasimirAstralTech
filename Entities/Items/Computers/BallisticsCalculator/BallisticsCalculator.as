#include "SpaceshipGlobal.as"
#include "SmallshipCommon.as"
#include "ComputerCommon.as"
#include "CommonFX.as"

void fighterBallistics( CBlob@ ownerBlob, ComputerBlobInfo@ ownerInfo, u32 ticksASecond )
{
	SmallshipInfo@ ship;
	if (!ownerBlob.get( "shipInfo", @ship )) 
	{ return; }

	CPlayer@ ownerPlayer = ownerBlob.getPlayer();
	if (ownerPlayer == null)
	{ return; }
	int playerPing = ownerPlayer.getPing();
	u32 pingTicks = (float(playerPing) / 1000.0f) * ticksASecond;

	Vec2f ownerPos = ownerInfo.current_pos;
	Vec2f ownerVel = ownerInfo.current_vel;
	int teamNum = ownerInfo.team_num;
	f32 ownerAngle = ownerInfo.blob_angle;

	f32 shotSpeed = ship.shot_speed;
	
	makeBlobTriangle(ownerPos, ownerAngle, Vec2f(8.0f, 6.0f)); //owner triangle

	CBlob@[] smallships;
	getBlobsByTag(smallTag, @smallships);
	for(uint i = 0; i < smallships.length(); i++)
	{
		CBlob@ b = smallships[i];
		if (b == null)
		{ continue; }

		if (b.getTeamNum() == teamNum)
		{ continue; }

		Vec2f bPos = b.getPosition();
		Vec2f bVel = b.getVelocity() - ownerVel;
		bPos += bVel * playerPing;

		Vec2f targetVec = bPos - ownerPos;
		f32 targetDist = targetVec.getLength();
		if (targetDist > 512) //too far away, don't continue rendering
		{ continue; }

		f32 travelTicks = targetDist / shotSpeed;
		Vec2f futureTargetPos = bPos + (bVel*travelTicks);
		
		targetVec = futureTargetPos - ownerPos;
		targetDist = targetVec.getLength();
		travelTicks = targetDist / shotSpeed;
		futureTargetPos = bPos + (bVel*travelTicks);

		f32 bAngle = b.getAngleDegrees();
		makeBlobTriangle(bPos, bAngle, Vec2f(8.0f, 6.0f)); //enemy triangle
		drawParticleLine( bPos, futureTargetPos, Vec2f_zero, greenConsoleColor, 0, 3.0f); //primary pip
		drawParticleCircle( futureTargetPos, 8.0f, Vec2f_zero, greenConsoleColor, 0, 4.0f);
	}
}