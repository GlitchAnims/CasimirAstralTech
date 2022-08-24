#include "TradingCommon.as"
#include "Descriptions.as"

#define SERVER_ONLY

int coinsOnDamageAdd = 2;
int coinsOnKillAdd = 10;
int coinsOnDeathLose = 10;
int min_coins = 50;
int max_coins = 100;

//
string cost_config_file = "tdm_vars.cfg";
bool kill_traders_and_shops = false;

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	if (blob.getName() == "team_station")
	{
		if (kill_traders_and_shops)
		{
			blob.server_Die();
			KillTradingPosts();
		}
		else
		{
			MakeTradeMenu(blob);
		}
	}
}

TradeItem@ addItemForCoin(CBlob@ this, const string &in name, int cost, const bool instantShipping, const string &in iconName, const string &in configFilename, const string &in description)
{
	if(cost <= 0) {
		return null;
	}

	TradeItem@ item = addTradeItem(this, name, 0, instantShipping, iconName, configFilename, description);
	if (item !is null)
	{
		AddRequirement(item.reqs, "coin", "", "Coins", cost);
		item.buyIntoInventory = true;
	}
	return item;
}

void MakeTradeMenu(CBlob@ trader)
{
	//load config

	if (getRules().exists("tdm_costs_config"))
		cost_config_file = getRules().get_string("tdm_costs_config");

	ConfigFile cfg = ConfigFile();
	cfg.loadFile(cost_config_file);

	s32 cost_burger = cfg.read_s32("cost_burger", 40);
	//CPUs
	s32 cost_ballistics = cfg.read_s32("cost_ballistics", 40);
	s32 cost_navcomp = cfg.read_s32("cost_navcomp", 30);
	s32 cost_targeting = cfg.read_s32("cost_targeting", 40);

	//ordinance
	s32 cost_aa = cfg.read_s32("cost_aa", 20);
	s32 cost_cruise = cfg.read_s32("cost_cruise", 30);
	s32 cost_emp = cfg.read_s32("cost_emp", 20);
	s32 cost_flare = cfg.read_s32("cost_flare", 10);

	//ships
	s32 cost_martyr = cfg.read_s32("cost_martyr", 120);
	s32 cost_balthazar = cfg.read_s32("cost_balthazar", 100);

	s32 menu_width = cfg.read_s32("trade_menu_width", 3);
	s32 menu_height = cfg.read_s32("trade_menu_height", 5);

	// build menu
	CreateTradeMenu(trader, Vec2f(menu_width, menu_height), "Buy weapons");
	addTradeSeparatorItem(trader, "$MENU_GENERIC$", Vec2f(3, 1));

	
	//yummy stuff
	addItemForCoin(trader, "Burger", cost_burger, true, "$food$", "food", Descriptions::food);
	//vehicles
	//addItemForCoin(trader, "Catapult", cost_catapult, true, "$catapult$", "catapult", Descriptions::catapult);
	//addItemForCoin(trader, "Ballista", cost_ballista, true, "$ballista$", "ballista", Descriptions::ballista);
	//CPUs
	addItemForCoin(trader, "Ballistics Calculator", cost_ballistics, true, "$ballistics_calc$", "ballistics_calc", Descriptions::ballistics_calc);
	addItemForCoin(trader, "Navigational Computer", cost_navcomp, true, "$nav_comp$", "nav_comp", Descriptions::nav_comp);
	addItemForCoin(trader, "Targeting Unit", cost_targeting, true, "$targeting_unit$", "targeting_unit", Descriptions::targeting_unit);

	addItemForCoin(trader, "AA Missiles", cost_aa, true, "$mat_arrows$", "mat_missile_aa", Descriptions::mat_missile_aa);
	//addItemForCoin(trader, "Cruise Missiles", cost_cruise, true, "$mat_bombarrows$", "mat_missile_cruise", Descriptions::mat_missile_cruise);
	//addItemForCoin(trader, "EMP Missiles", cost_emp, true, "$mat_waterarrows$", "mat_missile_emp", Descriptions::mat_missile_emp);
	addItemForCoin(trader, "Flares", cost_flare, true, "$mat_firearrows$", "mat_missile_flare", Descriptions::mat_missile_flare);
	addItemForCoin(trader, "Martyr", cost_martyr, true, "$mat_firearrows$", "martyr", Descriptions::buy_martyr);
	addItemForCoin(trader, "Balthazar", cost_balthazar, true, "$mat_firearrows$", "balthazar", Descriptions::buy_balthazar);
}

// load coins amount
void Reset(CRules@ this)
{
	//load the coins vars now, good a time as any
	if (this.exists("tdm_costs_config"))
		cost_config_file = this.get_string("tdm_costs_config");

	ConfigFile cfg = ConfigFile();
	cfg.loadFile(cost_config_file);

	coinsOnDamageAdd = cfg.read_s32("coinsOnDamageAdd", coinsOnDamageAdd);
	coinsOnKillAdd = cfg.read_s32("coinsOnKillAdd", coinsOnKillAdd);
	coinsOnDeathLose = cfg.read_s32("coinsOnDeathLose", coinsOnDeathLose);
	min_coins = cfg.read_s32("minCoinsOnRestart", min_coins);
	max_coins = cfg.read_s32("maxCoinsOnRestart", max_coins);

	kill_traders_and_shops = !(cfg.read_bool("spawn_traders_ever", true));

	if (kill_traders_and_shops)
	{
		KillTradingPosts();
	}

	//clamp coin vars each round
	for (int i = 0; i < getPlayersCount(); i++)
	{
		CPlayer@ player = getPlayer(i);
		if (player is null) continue;

		s32 coins = player.getCoins();
		if (min_coins >= 0) coins = Maths::Max(coins, min_coins);
		if (max_coins >= 0) coins = Maths::Min(coins, max_coins);
		player.server_setCoins(coins);
	}

}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onInit(CRules@ this)
{
	Reset(this);
}


void KillTradingPosts()
{
	CBlob@[] tradingposts;
	bool found = false;
	if (getBlobsByName("team_station", @tradingposts))
	{
		for (uint i = 0; i < tradingposts.length; i++)
		{
			CBlob @b = tradingposts[i];
			b.server_Die();
		}
	}
}

// give coins for killing

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData)
{
	if (victim !is null)
	{
		if (killer !is null)
		{
			if (killer !is victim && killer.getTeamNum() != victim.getTeamNum())
			{
				killer.server_setCoins(killer.getCoins() + coinsOnKillAdd);
			}
		}

		victim.server_setCoins(victim.getCoins() - coinsOnDeathLose);
	}
}

// give coins for damage

f32 onPlayerTakeDamage(CRules@ this, CPlayer@ victim, CPlayer@ attacker, f32 DamageScale)
{
	if (attacker !is null && attacker !is victim)
	{
		attacker.server_setCoins(attacker.getCoins() + DamageScale * coinsOnDamageAdd / this.attackdamage_modifier);
	}

	return DamageScale;
}
