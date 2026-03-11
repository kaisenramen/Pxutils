# Pxutils Plugin

An extension for **Aseprite** that helps with **pxls.space** workflows, including downscaling,
color reduction, and analysis. Designed with **Clueless** users is mind.

---

## Features

- **Colors** - Count the number of unique colors in a cel or selection. 
- **Reduce** - Map all pixels to a valid palette in a cel or selection.
- **Visual Size** - Count visible pixels in a cel or selection.
- **Nearest-Neighbor Downscale** - Detect integer upscales and resize accordingly.
- **Non-Integer Downscale** - Recover approximate original image after non-integer upscale.

## Installation

1. Download the [latest release](https://github.com/kaisenramen/Pxutils/releases) of your choice
(either the *base* or *extras* extension)
2. Double click the file and open with Aseprite
3. You should see a new menu option called "**Pxutils**" under **Edit**

## Usage

**Option 1: From menu**
- Click **Edit > Pxutils > Colors** or **Reduce** and click **OK**
- Click **Sprite > Visual Size** and click **OK**
- Click **Sprite > Downscale > Nearest-Neighbor** or **Non-Integer**

**Option 2: Keyboard shortcuts**
- You can use my keybinds from the *extras* extension, or assign your own in **Edit > Keyboard Shortcuts**
- If you installed with *extras*, the keybinds are as follows:
  - **Colors** - `Ctrl` + `Alt` + `C`
  - **Reduce** - `Ctrl` + `Alt` + `R`
  - **Visual Size** - `Ctrl` + `Alt` + `S`
  - **Nearest-Neighbor Downscale** - `Ctrl` + `Alt` + `D`
  - **Non-Integer Downscale** - `Ctrl` + `Alt` + `Shift` + `D`

You can restore default settings with **Edit > Pxutils > Restore Defaults**.

## Contributing

- For feature requests, open an issue with the *suggestion* tag.  
- Pull requests are welcome.

## License

This plugin is licensed under the MIT License.