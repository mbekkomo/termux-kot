# termux-kot
Private bot for Termux server, catches messages like a cat.

## Usage

```bash
# - Ensure Luvit is installed

# 1. Clone the repository with it's submodules
git clone https://github.com/UrNightmaree/termux-kot --recursive
# or if you already cloned without `--recursive` flag, run
git submodule update --init --recursive

# 2. Edit the template.config.json and rename it as `config.json`
nano template.config.json
mv template.config.json config.json

# 3. Install the dependency
lit install SinisterRectus/discordia

# 4. Run the bot
luvit main.lua
```
