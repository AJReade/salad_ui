defmodule SaladUI.Patcher.TailwindV4Patcher do
  @moduledoc """
  CSS-only patching for Tailwind v4 (Phoenix 1.8+)
  
  This module handles all CSS configuration for Tailwind v4, which uses
  CSS-based configuration instead of JavaScript config files.
  """

  @plugins [
    "@tailwindcss/typography",
    "tailwindcss-animate"
  ]

  @doc """
  Patches the app.css file to include SaladUI configuration for Tailwind v4.
  
  This adds:
  - @plugin directives for required plugins
  - @import for SaladUI CSS
  - CSS variables for color schemes
  """
  def patch_css(css_path, color_scheme \\ "gray") do
    content = File.read!(css_path)
    
    content
    |> ensure_salad_ui_import()
    |> add_plugins_if_missing(@plugins)
    |> add_color_variables_if_missing(color_scheme)
    |> then(&File.write!(css_path, &1))
  end

  defp ensure_salad_ui_import(content) do
    import_line = "@import \"./salad_ui.css\";"
    
    if String.contains?(content, import_line) do
      content
    else
      # Add after the last @import statement
      case Regex.run(~r/(@import[^;]+;)(?!.*@import)/s, content) do
        [last_import] ->
          String.replace(content, last_import, "#{last_import}\n#{import_line}")
        nil ->
          # No imports found, add at the beginning
          "#{import_line}\n\n#{content}"
      end
    end
  end

  defp add_plugins_if_missing(content, plugins) do
    missing_plugins = 
      plugins
      |> Enum.reject(&String.contains?(content, "@plugin \"#{&1}\""))
    
    if Enum.empty?(missing_plugins) do
      content
    else
      plugin_directives = 
        missing_plugins
        |> Enum.map(&"@plugin \"#{&1}\";")
        |> Enum.join("\n")
      
      # Add plugins after @import "tailwindcss"
      String.replace(
        content, 
        "@import \"tailwindcss\";", 
        "@import \"tailwindcss\";\n#{plugin_directives}"
      )
    end
  end

  defp add_color_variables_if_missing(content, color_scheme) do
    # Check if color variables are already present
    if String.contains?(content, ":root {") and String.contains?(content, "--background:") do
      content
    else
      color_vars = get_color_variables(color_scheme)
      content <> "\n\n" <> color_vars
    end
  end

  defp get_color_variables(color_scheme) do
    "@layer base {\n  :root {\n#{get_scheme_variables(color_scheme)}\n  }\n}"
  end

  defp get_scheme_variables("gray") do
    [
      "    --background: 0 0% 100%;",
      "    --foreground: 222.2 84% 4.9%;",
      "    --card: 0 0% 100%;",
      "    --card-foreground: 222.2 84% 4.9%;",
      "    --popover: 0 0% 100%;",
      "    --popover-foreground: 222.2 84% 4.9%;",
      "    --primary: 222.2 47.4% 11.2%;",
      "    --primary-foreground: 210 40% 98%;",
      "    --secondary: 210 40% 96%;",
      "    --secondary-foreground: 222.2 84% 4.9%;",
      "    --muted: 210 40% 96%;",
      "    --muted-foreground: 215.4 16.3% 46.9%;",
      "    --accent: 210 40% 96%;",
      "    --accent-foreground: 222.2 84% 4.9%;",
      "    --destructive: 0 84.2% 60.2%;",
      "    --destructive-foreground: 210 40% 98%;",
      "    --border: 214.3 31.8% 91.4%;",
      "    --input: 214.3 31.8% 91.4%;",
      "    --ring: 222.2 84% 4.9%;"
    ] |> Enum.join("\n")
  end

  defp get_scheme_variables("slate") do
    [
      "    --background: 0 0% 100%;",
      "    --foreground: 222.2 84% 4.9%;",
      "    --card: 0 0% 100%;",
      "    --card-foreground: 222.2 84% 4.9%;",
      "    --popover: 0 0% 100%;",
      "    --popover-foreground: 222.2 84% 4.9%;",
      "    --primary: 215.4 16.3% 46.9%;",
      "    --primary-foreground: 210 40% 98%;",
      "    --secondary: 210 40% 96%;",
      "    --secondary-foreground: 222.2 84% 4.9%;",
      "    --muted: 210 40% 96%;",
      "    --muted-foreground: 215.4 16.3% 46.9%;",
      "    --accent: 210 40% 96%;",
      "    --accent-foreground: 222.2 84% 4.9%;",
      "    --destructive: 0 84.2% 60.2%;",
      "    --destructive-foreground: 210 40% 98%;",
      "    --border: 214.3 31.8% 91.4%;",
      "    --input: 214.3 31.8% 91.4%;",
      "    --ring: 215.4 16.3% 46.9%;"
    ] |> Enum.join("\n")
  end

  defp get_scheme_variables(_), do: get_scheme_variables("gray")
end