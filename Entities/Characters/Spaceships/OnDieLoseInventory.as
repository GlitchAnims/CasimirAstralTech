// Fighter logic

#include "SpaceshipGlobal.as"
#include "ChargeCommon.as"

void onDie( CBlob@ this )
{
	CInventory@ inv = this.getInventory();
	if (inv == null)
	{ return; }

	int itemCount = inv.getItemsCount();
	print ("itemCount: "+ itemCount);

	inv.RemoveAll();

	int itemCountAfterDelete = inv.getItemsCount();
	print ("itemCountAfterDelete: "+ itemCountAfterDelete);
}