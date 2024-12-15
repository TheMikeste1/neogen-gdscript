local extractors = require("neogen.utilities.extractors")
local i = require("neogen.types.template").item
local nodes_utils = require("neogen.utilities.nodes")
local template = require("neogen.template")

local function function_extractor(node)
  local tree = {
    {
      retrieve = "first",
      node_type = "name",
      extract = true,
    },
    {
      retrieve = "first",
      node_type = "parameters",
      extract = true,
      as = i.Parameter,
    },
    {
      retrieve = "first",
      node_type = "return_type",
      extract = true,
      as = i.Return,
    },
  }

  local nodes = nodes_utils:matching_nodes_from(node, tree)
  return nodes
end

local function variable_extractor(node)
  local tree = {
    {
      retrieve = "first",
      node_type = "name",
      extract = true,
    },
    {
      retrieve = "first",
      node_type = "type",
      extract = true,
      as = i.Type,
    },
    {
      -- TODO: Extract the default value
      retrieve = "first",
      node_type = "value",
      extract = true,
    },
    {
      retrieve = "first",
      node_type = "annotations",
      subtree = {
        { retrieve = "all", node_type = "identifier", extract = true, recursive = true },
      },
    },
  }

  local nodes = nodes_utils:matching_nodes_from(node, tree)
  return nodes
end

local function trim_string(str)
  str = str:gsub("^[ \n\r]+", "")
  str = str:gsub("[ \n\r]+$", "")
  return str
end

local function extract_parameters(parameter_string)
  assert(type(parameter_string) == "string", "Invalid argument type")

  -- Example: "(a: float, b, c = 1, d: int = 1)"
  parameter_string = parameter_string:sub(2, #parameter_string - 1)
  local parameters = {}
  for param in parameter_string:gmatch("([^,]+)") do
    local assignment_parts = {}
    for part in param:gmatch("[^=]+") do
      part = trim_string(part)
      assignment_parts[#assignment_parts + 1] = part
    end

    if #assignment_parts > 2 then
      vim.notify("Too many parts to assignment for param " .. param .. "!", vim.log.levels.ERROR)
    end

    local lhs = assignment_parts[1]
    local default_value = assignment_parts[2]

    local lhs_parts = {}
    for part in lhs:gmatch("[^:]+") do
      part = trim_string(part)
      lhs_parts[#lhs_parts + 1] = part
    end

    if #lhs_parts > 2 then
      vim.notify("Too many parts to type for param " .. param .. "!", vim.log.levels.ERROR)
    end

    local name = lhs_parts[1]
    local type = lhs_parts[2]
    local param_definition = {
      name = name,
      type = type,
      default_value = default_value,
    }
    parameters[#parameters + 1] = param_definition
  end

  return parameters
end

return {
  parent = {
    class = { "source", "class_definition" },
    func = { "function_definition" },
    type = { "variable_statement" },
  },
  data = {
    class = {
      ["source"] = {
        ["0"] = {
          extract = function()
            -- No data to extract since we can't extract the file name
            return {
              is_file_class = true,
            }
          end,
        },
      },
      ["class_definition"] = {
        ["0"] = {
          extract = function()
            -- TODO
            return {
              is_file_class = false,
            }
          end,
        },
      },
    },
    func = {
      ["function_definition"] = {
        ["0"] = {
          extract = function(node)
            local nodes = function_extractor(node)
            local res = extractors:extract_from_matched(nodes)

            local parameters = {}
            if res.parameters then
              if #res.parameters > 1 then
                vim.notify("Too many parameter sets for " .. res.name .. ". Selecting first.", vim.log.levels.ERROR)
              end

              parameters = extract_parameters(res.parameters[1])
            end

            local result = {
              name = res.name,
              parameters = parameters,
            }
            return result
          end,
        },
      },
      -- TODO
    },
    type = {
      ["variable_statement"] = {
        ["0"] = {
          extract = function(node)
            local nodes = variable_extractor(node)
            local res = extractors:extract_from_matched(nodes)
            local result = {
              name = res.name,
              type = res.type,
              default_value = res.value,
              annotations = res.identifier,
            }
            return result
          end,
        },
      },
    },
  },
  locator = require("neogen.locators.default"),
  template = template
    :config({ use_default_comment = true })
    :add_default_annotation("gdscript")
    :add_annotation("gdscript_params"),
}
