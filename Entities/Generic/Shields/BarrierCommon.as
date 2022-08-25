const string shield_toggle_ID = "shield_toggle";
const string shieldModeNumString = "shield_mode_number";

bool doesBypassBarrier(CBlob@ barrier, Vec2f thisPos = Vec2f_zero, Vec2f thisVel = Vec2f_zero)
{
	if (barrier == null || barrier.hasTag("dead") || !barrier.get_bool("active") || thisPos == Vec2f_zero)
	{ return true; }

	Vec2f barrierPos = barrier.getPosition();
	f32 barrierRadius = barrier.getRadius();

	Vec2f dir = barrierPos - thisPos;

	f32 distanceFromCenter = dir.Length();
	distanceFromCenter /= barrierRadius;
	
	if (distanceFromCenter < 0.9f)
	{ return true;}

	// half and quarter check
	u16 shieldMode = barrier.get_u16(shieldModeNumString);
	if (shieldMode != 0)
	{
		float maxAngle = 90.0f;
		switch (shieldMode)
		{
			case 1:
			maxAngle = 90.0f;
			break;
			case 2:
			maxAngle = 45.0f;
			break;
		}

		Vec2f dirQ = thisPos - barrierPos;

		f32 angleQ = -dirQ.getAngleDegrees() + 360;
		f32 thisAngleQ = barrier.getAngleDegrees();
		
		f32 angleDiffQ = angleQ - thisAngleQ;
		angleDiffQ += angleDiffQ > 180 ? -360 : angleDiffQ < -180 ? 360 : 0;
		//angleDiffQ = (angleDiffQ + 180) % 360 - 180;
		//angleDiffQ = Maths::FMod(angleDiffQ + 180.0f, 360.0f) - 180.0f;

		if (angleDiffQ < -maxAngle || angleDiffQ > maxAngle)
		{ return true; }
	}

	// entry direction check
	f32 angle = dir.getAngleDegrees();
	f32 thisAngle = thisVel.getAngleDegrees();
	
	f32 angleDiff = Maths::Abs(angle - thisAngle);
	angleDiff = (angleDiff + 180) % 360 - 180;

	if (angleDiff > -90 && angleDiff < 90)
	{ return false; }

	return true;
}