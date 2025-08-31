defmodule ExampleWeb.PageLive do
  @moduledoc false
  use ExampleWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        key: "some value"
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.dialog id="my-dialog">
        <.dialog_trigger>
          <.button>Click me</.button>
        </.dialog_trigger>
        <.dialog_content>
          <p>Hello world!</p>
        </.dialog_content>
      </.dialog>
    </Layouts.app>
    """
  end
end
