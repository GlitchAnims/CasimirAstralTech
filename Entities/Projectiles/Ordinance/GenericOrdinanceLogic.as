// generic ordinance logic

#include "SpaceshipGlobal.as"
#include "OrdinanceCommon.as"

void onInit(CBlob@ this)
{
	this.Tag("projectile");
	this.Tag("hull");

	CShape@ shape = this.getShape();
	if (shape != null)
	{
		shape.getConsts().mapCollisions = true;
		shape.getConsts().bullet = true;
		shape.getConsts().net_threshold_multiplier = 4.0f;
		shape.SetGravityScale(0.0f);
	}

	this.set_bool(firstTickString, true); //SpaceshipGlobal.as
	this.set_bool(clientFirstTickString, true); //SpaceshipGlobal.as
	this.set_f32(shotLifetimeString, 1.0f); //SpaceshipGlobal.as

	this.set_Vec2f(targetLastVelString, Vec2f_zero);

	this.set_u32(hasTargetTicksString, 0);
	this.set_u16(targetNetIDString, 0);

	this.SetMapEdgeFlags(CBlob::map_collide_up | CBlob::map_collide_down | CBlob::map_collide_sides);

	this.addCommandID( homing_target_update_ID );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (this == null)
	{ return; }
	
    if (cmd == this.getCommandID(homing_target_update_ID)) // updates target for all clients
    {
		u16 newTargetNetID;
		bool resetTimer;
		
		if (!params.saferead_u16(newTargetNetID) || !params.saferead_bool(resetTimer)) return;

		this.set_u16(targetNetIDString, newTargetNetID);
		if (resetTimer) this.set_u32(hasTargetTicksString, 0);
	}
	//else if (cmd == this.getCommandID(homing_target_update_ID)) // resets lose target timer for all clients
}