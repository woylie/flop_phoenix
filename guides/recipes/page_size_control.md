# Page Size Control

To allow users to change the page size, you can create a component similar to
this:

```elixir
attr :current_size, :integer, required: true

def page_size_links(assigns) do
  ~H"""
  <ul class="page-size-links">
    <li
      :for={page_size <- [10, 20, 40, 60]}
      class={page_size == @current_size && "is-active"}
    >
      <.link phx-click="set-page-size" phx-value-size={page_size}>
        {page_size}
      </.link>
    </li>
  </ul>
  """
end
```

Render it with:

```heex
<.page_size_links current_size={@meta.page_size} />
```

And handle the event:

```elixir
  def handle_event("set-page-size", %{"size" => page_size}, socket) do
    flop = %{socket.assigns.meta.flop | page_size: page_size, limit: nil}
    path = Flop.Phoenix.build_path(~p"/pets", flop)

    {:noreply, push_patch(socket, to: path)}
  end
```
