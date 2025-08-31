defmodule Mix.Tasks.Salad.Setup do
  @moduledoc """
  Set up SaladUI in a Phoenix 1.8+ LiveView project with Tailwind v4.

  This task configures the complete SaladUI development environment by:

  * Adding TwMerge.Cache to the application supervision tree
  * Configuring CSS color scheme variables (default: gray)
  * Copying SaladUI CSS files to assets/css/
  * Patching CSS with SaladUI-specific plugins for Tailwind v4
  * Setting up JavaScript imports and LiveView hooks

  ## Usage

      mix salad.setup
      mix salad.setup --color-scheme slate
      mix salad.setup -c blue

  ## Options

    * `--color-scheme` (or `-c`) - Color scheme to use (default: "gray")
      Available schemes: gray, slate, stone, neutral, red, orange, amber,
      yellow, lime, green, emerald, teal, cyan, sky, blue, indigo, violet,
      purple, fuchsia, pink, rose

  ## What it does

  1. **TwMerge Integration** - Adds TwMerge.Cache as a supervised process for
     CSS class merging functionality

  2. **CSS Setup**
     - Copies salad_ui.css to assets/css/
     - Adds color scheme variables to app.css
     - Imports SaladUI styles into the main CSS file

  3. **Tailwind v4 CSS Configuration**
     - Adds @plugin directives to CSS for SaladUI-specific plugins
     - Adds CSS variables for color schemes
     - Works with Tailwind v4's CSS-based configuration

  4. **JavaScript Setup**
     - Uses Phoenix 1.8's built-in tailwindcss-animate
     - Patches app.js to import SaladUI components and hooks
     - Registers SaladUIHook with LiveView

  ## After running this task

  You can immediately start using SaladUI components in your templates:

      <.button>Click me</.button>
      <.dialog id="my-dialog">
        <.dialog_content>
          <p>Hello world!</p>
        </.dialog_content>
      </.dialog>

  ## Files modified

  * `lib/[app]/application.ex` - Adds TwMerge.Cache
  * `assets/css/app.css` - Adds @plugin directives, imports, and CSS variables
  * `assets/css/salad_ui.css` - Created
  * `assets/js/app.js` - Adds SaladUI imports and hooks

  ## Example

      # Use default gray color scheme
      mix salad.setup

      # Use slate color scheme
      mix salad.setup --color-scheme slate

      # Short form
      mix salad.setup -c blue
  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    {opts, _args} =
      OptionParser.parse!(igniter.args.argv,
        strict: [color_scheme: :string],
        aliases: [c: :color_scheme]
      )

    color_scheme = opts[:color_scheme] || "gray"

    Mix.shell().info("Setting up SaladUI for Phoenix 1.8 with Tailwind v4")
    Mix.shell().info("Compatible with DaisyUI - no conflicts")

    igniter
    |> patch_tw_merge()
    |> copy_salad_ui_css()
    |> patch_css_for_tailwind_v4(color_scheme)
    |> patch_app_js()
  end

  defp patch_tw_merge(igniter) do
    Igniter.Project.Application.add_new_child(igniter, TwMerge.Cache)
  end

  defp patch_css_for_tailwind_v4(igniter, color_scheme) do
    SaladUI.Patcher.TailwindV4Patcher.patch_css("./assets/css/app.css", color_scheme)
    igniter
  end


  defp copy_salad_ui_css(igniter) do
    source_file = assets_path("salad_ui.css")
    target_file = "./assets/css/salad_ui.css"

    Igniter.copy_template(igniter, source_file, target_file, [])
  end





  defp assets_path(directory) do
    Path.join([:code.priv_dir(:salad_ui), "static/assets", directory])
  end

  # Patch app.js to import library JavaScript
  @js_import """
  import SaladUI from "salad_ui";
  import "salad_ui/components/dialog";
  import "salad_ui/components/select";
  import "salad_ui/components/tabs";
  import "salad_ui/components/radio_group";
  import "salad_ui/components/popover";
  import "salad_ui/components/hover-card";
  import "salad_ui/components/collapsible";
  import "salad_ui/components/tooltip";
  import "salad_ui/components/accordion";
  import "salad_ui/components/slider";
  import "salad_ui/components/switch";
  import "salad_ui/components/dropdown_menu";
  """
  @js_hooks "SaladUI: SaladUI.SaladUIHook"
  defp patch_app_js(igniter) do
    app_js_path = "./assets/js/app.js"

    js_content =
      app_js_path
      |> File.read!()
      |> SaladUI.Patcher.JSPatcher.patch_js(@js_import, @js_hooks)

    File.write!(app_js_path, js_content)

    igniter
  end
end
