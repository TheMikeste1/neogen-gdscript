# neogen-gdscript

A Neogen plugin for GDScript.

## How to use

Add GDScript to Neogen's options:

```lua
require("neogen").setup({
  languages = {
    ["gdscript"] = require("neogen.configurations.gdscript"), -- Add this line
  },
})
```

Just make sure to load this plugin first!

lazy.nvim:

```lua
{
  "danymat/neogen",
  config = function()
    require("neogen").setup({
      languages = {
        ["gdscript"] = require("neogen.configurations.gdscript"),
      },
    })
  end,
  dependencies = {
    {
      "TheMikeste1/neogen-gdscript",
    },
  },
}
```
