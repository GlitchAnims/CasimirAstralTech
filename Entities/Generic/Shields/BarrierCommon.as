const string shield_toggle_ID = "shield_toggle";

bool doesBypassBarrier(CBlob@ barrier, Vec2f thisPos = Vec2f_zero, Vec2f thisVel = Vec2f_zero)
{
	if (barrier == null || barrier.hasTag("dead") || !barrier.get_bool("active") || thisPos == Vec2f_zero)
	{ return true; }

	Vec2f blobPos = barrier.getPosition();
	f32 blobRadius = barrier.getRadius();

	Vec2f dir = blobPos - thisPos;

	f32 distanceFromCenter = dir.Length();
	distanceFromCenter /= blobRadius;
	
	if (distanceFromCenter < 0.9f)
	{ return true;}

	f32 angle = dir.getAngleDegrees();
	f32 thisAngle = thisVel.getAngleDegrees();
	
	f32 angleDiff = Maths::Abs(angle - thisAngle);
	angleDiff = (angleDiff + 180) % 360 - 180;

	if (angleDiff > -90 && angleDiff < 90)
	{ return false; }

	return true;
}