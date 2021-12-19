#include "SpaceshipGlobal.as"

void onInit( CBlob@ this )
{
    this.addCommandID( shot_command_ID );
	this.addCommandID( hit_command_ID );
	this.addCommandID( "pulsed" );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID(shot_command_ID)) // 1 shot instance
    {
		if (!isServer())
		{ return; }
		
		u16 ownerID;
		u8 shotType;
		f32 lifeTime;
		Vec2f blobPos;
		Vec2f blobVel;
		
		if (!params.saferead_u16(ownerID)) return;
		if (!params.saferead_u8(shotType)) return;
		if (!params.saferead_f32(lifeTime)) return;

		CBlob@ ownerBlob = getBlobByNetworkID(ownerID);
		if (ownerBlob == null || ownerBlob.hasTag("dead"))
		{ return; }

		string blobName = getBulletName(shotType);

		/*
		if (!params.saferead_Vec2f(blobPos)) return;
		if (!params.saferead_Vec2f(blobVel)) return;
		*/

		//bool !params.saferead_u16(ownerID);
		//bool !params.saferead_u8(shotType);

		while (params.saferead_Vec2f(blobPos) && params.saferead_Vec2f(blobVel)) //immediately stops if something fails
		{
			if (blobPos == Vec2f_zero || blobVel == Vec2f_zero)
			{ return; }

			CBlob@ blob = server_CreateBlob( blobName , ownerBlob.getTeamNum(), blobPos);
			if (blob !is null)
			{
				blob.IgnoreCollisionWhileOverlapped( ownerBlob );
				blob.SetDamageOwnerPlayer( ownerBlob.getPlayer() );
				blob.setVelocity( blobVel );
				blob.set_f32(shot_lifetime_string, lifeTime);
			}
		}
	}
	else if (cmd == this.getCommandID(hit_command_ID)) // if a shot hits, this gets sent
    {
		
	}
}