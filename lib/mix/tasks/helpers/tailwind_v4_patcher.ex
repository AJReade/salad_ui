defmodule SaladUI.Patcher.TailwindV4Patcher do
  @moduledoc """
  CSS-only patching for Tailwind v4 (Phoenix 1.8+)
  
  This module handles all CSS configuration for Tailwind v4, which uses
  CSS-based configuration instead of JavaScript config files.
  """

  @plugins [
    "@tailwindcss/typography"
  ]
  
  @vendor_plugins [
    "../vendor/tailwindcss-animate"
  ]
  
  @salad_imports [
    "@import \"./salad_ui.css\";"
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
    |> add_vendor_plugins_if_missing(@vendor_plugins)
    |> add_theme_configuration_if_missing()
    |> add_color_variables_if_missing(color_scheme)
    |> then(&File.write!(css_path, &1))
  end

  defp ensure_salad_ui_import(content) do
    import_lines = Enum.join(@salad_imports, "\n")
    
    # Check if all imports are already present
    all_present = Enum.all?(@salad_imports, &String.contains?(content, &1))
    
    if all_present do
      content
    else
      # Add after the tailwindcss import statement
      case Regex.run(~r/@import\s+"tailwindcss"[^;]*;/s, content) do
        [tailwind_import] ->
          String.replace(content, tailwind_import, "#{tailwind_import}\n#{import_lines}")
        nil ->
          # No tailwindcss import found, add at the beginning
          "#{import_lines}\n\n#{content}"
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
      case Regex.run(~r/@import\s+"tailwindcss"[^;]*;/s, content) do
        [tailwind_import] ->
          String.replace(
            content, 
            tailwind_import, 
            "#{tailwind_import}\n#{plugin_directives}"
          )
        nil ->
          content
      end
    end
  end

  defp add_vendor_plugins_if_missing(content, vendor_plugins) do
    missing_plugins = 
      vendor_plugins
      |> Enum.reject(&String.contains?(content, "@plugin \"#{&1}\";"))
    
    if Enum.empty?(missing_plugins) do
      content
    else
      plugin_directives = 
        missing_plugins
        |> Enum.map(&"@plugin \"#{&1}\";")
        |> Enum.join("\n")
      
      # Add vendor plugins after existing plugins
      # Find all @plugin directives and add after the last one
      plugin_matches = Regex.scan(~r/@plugin\s+"[^"]*"[^;]*;/s, content)
      if Enum.empty?(plugin_matches) do
        content
      else
        # Get the last plugin match
        [last_plugin] = List.last(plugin_matches)
        String.replace(content, last_plugin, "#{last_plugin}\n#{plugin_directives}", global: false)
      end
    end
  end

  defp add_theme_configuration_if_missing(content) do
    # Check if @theme configuration is already present
    if String.contains?(content, "@theme {") do
      content
    else
      theme_config = get_theme_configuration()
      
      # Add @theme after salad_ui.css import
      case Regex.run(~r/@import\s+"\.\/salad_ui\.css"[^;]*;/s, content) do
        [salad_import] ->
          String.replace(content, salad_import, "#{salad_import}\n\n#{theme_config}")
        nil ->
          # If no salad_ui import found, add after tailwindcss import
          case Regex.run(~r/@import\s+"tailwindcss"[^;]*;/s, content) do
            [tailwind_import] ->
              String.replace(content, tailwind_import, "#{tailwind_import}\n\n#{theme_config}")
            nil ->
              "#{theme_config}\n\n#{content}"
          end
      end
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

  defp get_theme_configuration do
    """
    @theme {
      /* Colors */
      --color-accent: hsl(var(--accent));
      --color-accent-foreground: hsl(var(--accent-foreground));
      --color-background: hsl(var(--background));
      --color-border: hsl(var(--border));
      --color-card: hsl(var(--card));
      --color-card-foreground: hsl(var(--card-foreground));
      --color-destructive: hsl(var(--destructive));
      --color-destructive-foreground: hsl(var(--destructive-foreground));
      --color-foreground: hsl(var(--foreground));
      --color-input: hsl(var(--input));
      --color-muted: hsl(var(--muted));
      --color-muted-foreground: hsl(var(--muted-foreground));
      --color-popover: hsl(var(--popover));
      --color-popover-foreground: hsl(var(--popover-foreground));
      --color-primary: hsl(var(--primary));
      --color-primary-foreground: hsl(var(--primary-foreground));
      --color-ring: hsl(var(--ring));
      --color-secondary: hsl(var(--secondary));
      --color-secondary-foreground: hsl(var(--secondary-foreground));
      
      /* Sidebar colors */
      --color-sidebar: hsl(var(--sidebar-background));
      --color-sidebar-foreground: hsl(var(--sidebar-foreground));
      --color-sidebar-primary: hsl(var(--sidebar-primary));
      --color-sidebar-primary-foreground: hsl(var(--sidebar-primary-foreground));
      --color-sidebar-accent: hsl(var(--sidebar-accent));
      --color-sidebar-accent-foreground: hsl(var(--sidebar-accent-foreground));
      --color-sidebar-border: hsl(var(--sidebar-border));
      --color-sidebar-ring: hsl(var(--sidebar-ring));
      
      /* Chart colors */
      --color-chart-1: hsl(var(--chart-1));
      --color-chart-2: hsl(var(--chart-2));
      --color-chart-3: hsl(var(--chart-3));
      --color-chart-4: hsl(var(--chart-4));
      --color-chart-5: hsl(var(--chart-5));
    }\
    """
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
      "    --ring: 222.2 84% 4.9%;",
      "",
      "    /* Sidebar variables */",
      "    --sidebar-background: 0 0% 98%;",
      "    --sidebar-foreground: 240 5.3% 26.1%;",
      "    --sidebar-primary: 240 5.9% 10%;",
      "    --sidebar-primary-foreground: 0 0% 98%;",
      "    --sidebar-accent: 240 4.8% 95.9%;",
      "    --sidebar-accent-foreground: 240 5.9% 10%;",
      "    --sidebar-border: 220 13% 91%;",
      "    --sidebar-ring: 217.2 32.6% 17.5%;",
      "",
      "    /* Chart variables */",
      "    --chart-1: 12 76% 61%;",
      "    --chart-2: 173 58% 39%;",
      "    --chart-3: 197 37% 24%;",
      "    --chart-4: 43 74% 66%;",
      "    --chart-5: 27 87% 67%;"
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
      "    --ring: 215.4 16.3% 46.9%;",
      "",
      "    /* Sidebar variables */",
      "    --sidebar-background: 0 0% 98%;",
      "    --sidebar-foreground: 240 5.3% 26.1%;",
      "    --sidebar-primary: 240 5.9% 10%;",
      "    --sidebar-primary-foreground: 0 0% 98%;",
      "    --sidebar-accent: 240 4.8% 95.9%;",
      "    --sidebar-accent-foreground: 240 5.9% 10%;",
      "    --sidebar-border: 220 13% 91%;",
      "    --sidebar-ring: 217.2 32.6% 17.5%;",
      "",
      "    /* Chart variables */",
      "    --chart-1: 12 76% 61%;",
      "    --chart-2: 173 58% 39%;",
      "    --chart-3: 197 37% 24%;",
      "    --chart-4: 43 74% 66%;",
      "    --chart-5: 27 87% 67%;"
    ] |> Enum.join("\n")
  end

  defp get_scheme_variables(_), do: get_scheme_variables("gray")
end