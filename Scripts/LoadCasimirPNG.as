// TDM PNG loader base class - extend this to add your own PNG loading functionality!

#include "BasePNGLoader.as";
#include "MinimapHook.as";

// TDM custom map colors
namespace tdm_colors
{
	enum color
	{
		martyr_1 = 0xFF8888FF,
		martyr_2 = 0xFFFF8888,
		balthazar_1 = 0xFF7888FF,
		balthazar_2 = 0xFFFF7888,
		wanderer_1 = 0xFF6888FF,
		wanderer_2 = 0xFFFF6888,
		faraday_1 = 0xFF5888FF,
		faraday_2 = 0xFFFF5888
	};
}

//the loader

class TDMPNGLoader : PNGLoader
{
	TDMPNGLoader()
	{
		super();
	}

	//override this to extend functionality per-pixel.
	void handlePixel(const SColor &in pixel, int offset) override
	{
		PNGLoader::handlePixel(pixel, offset);

		switch (pixel.color)
		{
			case tdm_colors::martyr_1: autotile(offset); spawnBlob(map, "martyr", offset, 0); break;
			case tdm_colors::martyr_2: autotile(offset); spawnBlob(map, "martyr", offset, 1); break;
			case tdm_colors::balthazar_1: autotile(offset); spawnBlob(map, "balthazar", offset, 0); break;
			case tdm_colors::balthazar_2: autotile(offset); spawnBlob(map, "balthazar", offset, 1); break;
			case tdm_colors::wanderer_1: autotile(offset); spawnBlob(map, "wanderer", offset, 0); break;
			case tdm_colors::wanderer_2: autotile(offset); spawnBlob(map, "wanderer", offset, 1); break;
			case tdm_colors::faraday_1: autotile(offset); spawnBlob(map, "faraday", offset, 0); break;
			case tdm_colors::faraday_2: autotile(offset); spawnBlob(map, "faraday", offset, 1); break;
		};
	}
};

// --------------------------------------------------

bool LoadMap(CMap@ map, const string& in fileName)
{
	print("LOADING TDM PNG MAP " + fileName);

	TDMPNGLoader loader();

	MiniMap::Initialise();

	return loader.loadMap(map , fileName);
}