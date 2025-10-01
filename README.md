# SG-OutfitBag

A comprehensive outfit management system for QBCore FiveM servers that allows players to store and share their outfits using placeable bags.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Framework](https://img.shields.io/badge/framework-QBCore-red.svg)
![Version](https://img.shields.io/badge/version-1.0.0-green.svg)

## Features

- **Two Types of Outfit Bags**
  - Small Outfit Bag
  - Large Outfit Bag (with sharing capabilities)

- **Realistic Interactions**
  - Place bags in the world
  - Animated outfit changes
  - Smooth animations for placing and picking up bags
  - Realistic clothing change sequences

- **Advanced Outfit Management**
  - Save current outfits
  - Store multiple outfits per bag
  - Share bags with other players (Large Bag only)
  - Persistent storage using database

- **QB-Target Integration**
  - Easy-to-use targeting system
  - Multiple interaction options
  - Context-sensitive actions

# Video Preview
[![SG-OutfitBag Preview](https://img.youtube.com/vi/7UzDZ4c9FvE/0.jpg)](https://youtu.be/7UzDZ4c9FvE)

## Dependencies

- [QBCore Framework](https://github.com/qbcore-framework)
- [qb-target](https://github.com/qbcore-framework/qb-target)
- [qb-input](https://github.com/qbcore-framework/qb-input)
- [qb-menu](https://github.com/qbcore-framework/qb-menu)
- [oxmysql](https://github.com/overextended/oxmysql)

## Installation

1. Download the resource
2. Place it in your server's resources directory
3. Copy the contents from the `install` folder:
   - Copy `items.lua` contents to your `qb-core/shared/items.lua`
   - Copy the inventory images (`smalloutfitbag.png` and `largeoutfitbag.png`) to your inventory images folder:
     - For `qb-inventory`: Copy to `qb-inventory/html/images/`

4. Add the following to your server.cfg:
```
ensure sg-outfitbag
```

5. The database table will be created automatically when the script starts

## Configuration

You can modify the following settings in `config.lua`:

```lua
Config = {
    Debug = false,                    -- Enable debug mode
    SmallOutfit = 'smalloutfitbag',  -- Item name for small bag
    LargeOutfit = 'largeoutfitbag',  -- Item name for large bag
    DatabaseTable = 'sg_outfits'      -- Database table name
}
```

## Usage

### Basic Controls
1. Use the outfit bag from your inventory to place it
2. Target the bag to:
   - Open the outfit menu
   - Save current outfit
   - Change into saved outfits
   - Pick up the bag
   - Share the bag (Large bag only)

### Saving Outfits
1. Place the bag
2. Target the bag and select "Open Bag"
3. Choose "Save Current Outfit"
4. Enter a name for your outfit

### Changing Outfits
1. Target a placed bag
2. Select "Open Bag"
3. Choose the outfit you want to wear
4. Watch the realistic changing animation

### Sharing Bags (Large Bag Only)
1. Place the large outfit bag
2. Target the bag
3. Select "Share Bag"
4. Enter the player ID
5. The selected player will now have access to your bag

## Support

For support, please create an issue on the GitHub repository or contact me through:
- Discord: [[sgMAGLERA/ME](https://discord.gg/DxAWqUBaGB)]

## Credits

- Author: sgMAGLERA
- Special thanks to the QBCore community

## License

This project is licensed under the GNU GENERAL PUBLIC LICENSE Version 3 - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the Project
2. Create your Feature Branch
3. Commit your Changes
4. Push to the Branch
5. Open a Pull Request

## Changelog

### Version 1.0.0
- Initial release
- Basic outfit management system
- Two types of bags
- Sharing functionality
- QB-Target integration
- Animated outfit changes
