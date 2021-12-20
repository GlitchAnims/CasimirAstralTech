
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
	print ("angle: "+ angle);
	print ("thisAngle: "+ thisAngle);
	
	f32 angleDiff = Maths::Abs(angle - thisAngle);
	print ("angleDiff: "+ angleDiff);
	angleDiff = (angleDiff + 180) % 360 - 180;
	//angleDiff = Maths::FMod(angleDiff + 180, 360.0f) - 180;
	print ("angleDiff2: "+ angleDiff);
	print ("<<<<<<<<<>>>>>>>>>");

	if (angleDiff > -90 && angleDiff < 90)
	{ 
		print ("blocked");
		print ("-----------------");
		return false;
	}
	print ("passed");
	print ("-----------------");

	return true;
}