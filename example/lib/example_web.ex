defmodule ExampleWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use ExampleWeb, :controller
      use ExampleWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]

      use Gettext, backend: ExampleWeb.Gettext

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # Translation
      use Gettext, backend: ExampleWeb.Gettext

      # HTML escaping functionality
      import Phoenix.HTML

       # Core UI components (except the ones that clash with Salad UI)
      import ExampleWeb.CoreComponents,
        except: [button: 1, icon: 1, label: 1, input: 1, table: 1]

      # Import ALL Salad UI components - these take priority
      import ExampleWeb.Components.UI.Accordion
      import ExampleWeb.Components.UI.Alert
      import ExampleWeb.Components.UI.AlertDialog
      import ExampleWeb.Components.UI.Avatar
      import ExampleWeb.Components.UI.Badge
      import ExampleWeb.Components.UI.Breadcrumb
      import ExampleWeb.Components.UI.Button
      import ExampleWeb.Components.UI.Card
      import ExampleWeb.Components.UI.Chart
      import ExampleWeb.Components.UI.Checkbox
      import ExampleWeb.Components.UI.Collapsible
      import ExampleWeb.Components.UI.Command
      import ExampleWeb.Components.UI.Dialog
      import ExampleWeb.Components.UI.DropdownMenu
      import ExampleWeb.Components.UI.Form
      import ExampleWeb.Components.UI.HoverCard
      import ExampleWeb.Components.UI.Icon
      import ExampleWeb.Components.UI.Input
      import ExampleWeb.Components.UI.Label
      import ExampleWeb.Components.UI.Menu
      import ExampleWeb.Components.UI.Pagination
      import ExampleWeb.Components.UI.Popover
      import ExampleWeb.Components.UI.Progress
      import ExampleWeb.Components.UI.RadioGroup
      import ExampleWeb.Components.UI.ScrollArea
      import ExampleWeb.Components.UI.Select
      import ExampleWeb.Components.UI.Separator
      import ExampleWeb.Components.UI.Sheet
      import ExampleWeb.Components.UI.Sidebar
      import ExampleWeb.Components.UI.Skeleton
      import ExampleWeb.Components.UI.Slider
      import ExampleWeb.Components.UI.Switch
      import ExampleWeb.Components.UI.Table
      import ExampleWeb.Components.UI.Tabs
      import ExampleWeb.Components.UI.Textarea
      import ExampleWeb.Components.UI.Toggle
      import ExampleWeb.Components.UI.ToggleGroup
      import ExampleWeb.Components.UI.Tooltip

      # Common modules used in templates
      alias Phoenix.LiveView.JS
      alias ExampleWeb.Layouts

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: ExampleWeb.Endpoint,
        router: ExampleWeb.Router,
        statics: ExampleWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
