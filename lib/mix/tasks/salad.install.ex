defmodule Mix.Tasks.Salad.Install do
  @moduledoc """
  Install SaladUI components and assets for Phoenix 1.8+ with Tailwind v4.

  ## Usage

      mix salad.install
      mix salad.install --prefix MyUIWeb.Components.UI
      mix salad.install --color-scheme slate
      mix salad.install --prefix CustomComponents --color-scheme blue

  ## Requirements

  - Phoenix 1.8+
  - LiveView 1.1.8+
  - Tailwind CSS v4
  """
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    Mix.shell().info("Installing SaladUI for Phoenix 1.8 with Tailwind v4")
    Mix.shell().info("Compatible with DaisyUI - no conflicts")

    # Parse command-line arguments
    {opts, _args} =
      OptionParser.parse!(igniter.args.argv,
        strict: [prefix: :string, color_scheme: :string],
        aliases: [p: :prefix, c: :color_scheme]
      )

    prefix = opts[:prefix] || get_default_prefix(igniter)
    color_scheme = opts[:color_scheme] || "gray"

    igniter
    |> setup_base_config(color_scheme)
    |> copy_javascript_files()
    |> copy_component_files(prefix)
    |> patch_app_js_with_local_imports()
  end

  # Setup base configuration for Tailwind v4
  defp setup_base_config(igniter, color_scheme) do
    igniter
    |> patch_tw_merge()
    |> copy_salad_ui_css()
    |> patch_css_for_tailwind_v4(color_scheme)
  end

  # Copy all JavaScript files to assets/js/ui/
  defp copy_javascript_files(igniter) do
    {:ok, dep_path} = find_salad_ui_dep()
    source_dir = Path.join([dep_path, "assets/salad_ui"])
    target_dir = "./assets/js/ui"

    # Create target directory if it doesn't exist
    File.mkdir_p!(target_dir)

    # Get all .js files from the source directory
    js_files = Path.wildcard(Path.join(source_dir, "**/*.js"))

    Enum.reduce(js_files, igniter, fn source_file, acc_igniter ->
      # Get relative path from source directory
      relative_path = Path.relative_to(source_file, source_dir)
      target_file = Path.join(target_dir, relative_path)

      # Create subdirectories if needed
      target_file |> Path.dirname() |> File.mkdir_p!()

      # Copy the file
      Igniter.copy_template(acc_igniter, source_file, target_file, [])
    end)
  end

  # Copy all component files to lib/<app>_web/components/ui/
  defp copy_component_files(igniter, prefix) do
    {:ok, dep_path} = find_salad_ui_dep()

    app_name = get_app_name(igniter)
    source_dir = Path.join([dep_path, "lib/salad_ui"])
    target_dir = "./lib/#{app_name}_web/components/ui"

    # Create target directory if it doesn't exist
    File.mkdir_p!(target_dir)

    # Get all .ex files from the source directory
    component_files =
      Path.wildcard(Path.join(source_dir, "**/*.ex"))

    igniter =
      Enum.reduce(component_files, igniter, fn source_file, acc_igniter ->
        filename = Path.basename(source_file)
        target_file = Path.join(target_dir, filename)

        # Read source content and transform it
        source_content = File.read!(source_file)
        transformed_content = transform_component_content(source_content, prefix)

        # Write transformed content to target
        Igniter.create_new_file(acc_igniter, target_file, transformed_content)
      end)

    # copy root index file
    ui_file = [Path.join([dep_path, "lib/salad_ui.ex"])]

    content =
      ui_file
      |> File.read!()
      |> transform_component_content(prefix)

    Igniter.create_new_file(igniter, Path.join(target_dir, "ui.ex"), content)
  end

  # Transform component content to replace module prefix
  defp transform_component_content(content, prefix) do
    content
    |> String.replace("defmodule SaladUI", "defmodule #{prefix}")
    |> String.replace("use SaladUI, :component", "use #{prefix}, :component")
    |> String.replace("import SaladUI.", "import #{prefix}.")
    |> String.replace("alias SaladUI.", "alias #{prefix}.")
    |> replace_component_calls_with_prefix(prefix)
  end

  # Replace component calls with custom prefix
  defp replace_component_calls_with_prefix(content, prefix) when prefix != "SaladUI" do
    String.replace(content, "SaladUI.", prefix <> ".")
  end

  defp replace_component_calls_with_prefix(content, _prefix), do: content

  # Patch app.js with local imports instead of external package imports
  defp patch_app_js_with_local_imports(igniter) do
    app_js_path = "./assets/js/app.js"

    js_import = """
    import SaladUI from "./ui/index.js";
    import "./ui/components/dialog.js";
    import "./ui/components/select.js";
    import "./ui/components/tabs.js";
    import "./ui/components/radio_group.js";
    import "./ui/components/popover.js";
    import "./ui/components/hover-card.js";
    import "./ui/components/collapsible.js";
    import "./ui/components/tooltip.js";
    import "./ui/components/accordion.js";
    import "./ui/components/slider.js";
    import "./ui/components/switch.js";
    import "./ui/components/dropdown_menu.js";
    """

    js_hooks = "SaladUI: SaladUI.SaladUIHook"

    js_content =
      app_js_path
      |> File.read!()
      |> SaladUI.Patcher.JSPatcher.patch_js(js_import, js_hooks)

    File.write!(app_js_path, js_content)

    igniter
  end

  # Helper functions (copied from salad.setup)
  defp patch_tw_merge(igniter) do
    Igniter.Project.Application.add_new_child(igniter, TwMerge.Cache)
  end


  defp copy_salad_ui_css(igniter) do
    source_file = assets_path("salad_ui.css")
    target_file = "./assets/css/salad_ui.css"

    Igniter.copy_template(igniter, source_file, target_file, [])
  end



  defp patch_css_for_tailwind_v4(igniter, color_scheme) do
    SaladUI.Patcher.TailwindV4Patcher.patch_css("./assets/css/app.css", color_scheme)
    igniter
  end


  # Helper functions for paths
  defp assets_path(directory) do
    Path.join([:code.priv_dir(:salad_ui), "static/assets", directory])
  end

  defp find_salad_ui_dep do
    Mix.Dep.load_and_cache()
    |> Enum.find(&(&1.app == :salad_ui))
    |> case do
      %Mix.Dep{opts: opts} = dep ->
        {:ok, opts[:path] || default_dep_path(dep)}

      nil ->
        {:error, "SaladUI not found in dependencies"}
    end
  end

  defp default_dep_path(dep) do
    Path.join([File.cwd!(), "deps", Atom.to_string(dep.app)])
  end

  defp get_app_name(igniter) do
    Igniter.Project.Application.app_name(igniter)
  end

  defp get_default_prefix(igniter) do
    app_name = get_app_name(igniter)
    Macro.camelize("#{app_name}_ui")
  end
end
