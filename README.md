# Pxutils Plugin

An extension for **Aseprite** that helps with **pxls.space** workflows, including downscaling,
color reduction, and analysis. Designed with **Clueless** users is mind.

---

## Features

- **Colors** - Count the number of unique colors in a sprite or selection. 
- **Reduce** - Map all pixels to a valid palette in a sprite or selection.
- **Visual Size** - Count visible pixels in a sprite or selection.
- **Nearest-Neighbor Downscale** - Detect integer upscales and resize accordingly.
- **Non-Integer Downscale** - Recover approximate original image after non-integer upscale.

## Installation

1. Download the [latest release](https://github.com/kaisenramen/Pxutils/releases) of your choice
(either the *base* \[recommended\] or *extras* extension)
2. Double click the file and open with Aseprite
3. You should see a new menu option called "**Pxutils**" under **Edit**

(As of v1.0, the only difference between *base* and *extras* is that *extras* registers every single Pxls palette to your presets.)
## Usage

**Option 1: From menu**
- Click **Edit > Pxutils > Colors** or **Reduce** and click **OK**
- Click **Sprite > Visual Size** and click **OK**
- Click **Sprite > Downscale > Nearest-Neighbor** or **Non-Integer**

**Option 2: Keyboard shortcuts**
- You can assign keybinds via **Edit > Keyboard Shortcuts**
- Just search "pxutils" and "sprite" and they should come up

You **must** allow file access in the popup so that the plugin access GPL files.
You can restore default settings with **Edit > Pxutils > Restore Defaults**.

## Contributing

- For feature requests, open an issue with the *enhancement* tag.  
- Pull requests are welcome.

## License

This plugin is licensed under the MIT License.
