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
      <p>Testing installation</p>
    </Layouts.app>
    """
  end
end
