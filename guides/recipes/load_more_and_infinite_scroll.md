# Load More and Infinite Scroll

You can use Flop's cursor pagination to implement load-more buttons and infinite
scroll.

Let's start with a basic "Load More" button.

## Load More Button

We'll define a basic schema:

```elixir
defmodule Petshop.Pets.Pet do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Flop.Schema,
           filterable: [:name],
           sortable: [:id],
           default_order: %{order_by: [:id], order_directions: [:desc]},
           default_limit: 50}

  schema "pets" do
    field :name, :string

    timestamps(type: :utc_datetime)
  end
end
```

We derive the `Flop.Schema` protocol, make the `id` column sortable, set the
default order to `id DESC`, and set the default limit to 50.

Then we define a list function:

```elixir
def list_pets(params) do
  Flop.validate_and_run!(Pet, params,
    for: Pet,
    default_pagination_type: :first,
    pagination_types: [:first],
    replace_invalid_params: true,
    filtering: false,
    ordering: false
  )
end
```

We set the default pagination type to `:first`, so that we get a response with
cursors even if no pagination parameters were passed. We chose `:first` because
the default order in the schema already sorts by ID descending. We also enable
`replace_invalid_params`, so that invalid parameters are silently ignored, and
we disable ordering and filtering via parameters.

In the `handle_params` function of our LiveView, we simply call the list
function, assign the `meta` struct, and stream the pets.

```elixir
@impl true
def handle_params(params, _url, socket) do
  {pets, meta} = Pets.list_pets(params)
  {:noreply, socket |> stream(:pets, pets) |> assign(:meta, meta)}
end
```

In our HEEx template, we're going to use a basic Flop table to render the
pets (but you could use any other component here), and we render the
"Load More" link. We only render the link after checking whether there is
indeed a next page.

```heex
<Flop.Phoenix.table
  id="pets"
  items={@streams.pets}
  meta={@meta}
  on_sort={JS.push("sort-table")}
  row_click={fn {_id, pet} -> JS.navigate(~p"/pets/#{pet}") end}
>
  <:col :let={{_id, pet}} label="Name">{pet.name}</:col>
  <:action :let={{_id, pet}}>
    <div class="sr-only">
      <.link navigate={~p"/pets/#{pet}"}>Show</.link>
    </div>
  </:action>
</Flop.Phoenix.table>

<p :if={@meta.has_next_page?}>
  <.link patch={~p"/pets?after=#{@meta.end_cursor}"}>Load More</.link>
</p>
```

The "Load More" link just attaches the end cursor as `after` parameter to the
base URL. A click then triggers the `handle_params` function, which passes the
parameter on to the list function. And since the end cursor is in the URL, the
user can reload the page or the LiveView can be re-mounted without the user
losing their position in the list.

And that's it - you should now have a working "Load More" button.

## Infinite Scroll

Now let's add infinite scroll to the view. First, we'll add a new hook to our
`assets/app.js`:

```js
let Hooks = {};

Hooks.InfiniteScroll = {
  mounted() {
    observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            this.pushEvent("load-more", {});
          }
        });
      },
      {
        root: null,
        rootMargin: "0px",
        threshold: 1.0,
      },
    );

    const anchorId = this.el.dataset.anchorId;
    const anchor = document.getElementById(anchorId);

    if (anchor) {
      observer.observe(anchor);
    } else {
      console.error(`Anchor element not found: ${anchorId}`);
    }
  },
};
```

We're using an `IntersectionObserver` to observe an anchor that is referenced with
a data attribute (`data-anchor-id`) on the hook element.

We then ensure to pass the hook when we create the LiveSocket:

```js
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});
```

And that's it on the JavaScript side. In our HEEx template, we wrap our table
and "Load More" link into a `div`, to which we add the `phx-hook` attribute.

```heex
<div
  id="main-content"
  phx-hook="InfiniteScroll"
  data-anchor-id="load-more-anchor"
>
  <Flop.Phoenix.table ...>
    <%!-- etc. --%>
  </Flop.Phoenix.table>

  <p :if={@meta.has_next_page?} id="load-more-anchor">
    <.link patch={~p"/pets?after=#{@meta.end_cursor}"}>Load More</.link>
  </p>
</div>
```

Note that the paragraph that contains the "Load More" link acts as an anchor: We
gave it an ID and referenced it in the `data-anchor-id` attribute of the `div`.

We need one final change: The hook doesn't patch the URL directly, but pushes a
`load-more` event to the server. If we wanted to patch the URL directly with the
hook, we'd need to tell it the base URL and the end cursor. While possible, it's
probably easier to handle this on the server-side.

To handle the event, we need to add a `handle_event` function to our LiveView.
It checks whether there is indeed an end cursor and patches the URL just like
a click on the "Load More" link would do.

```elixir
def handle_event("load-more", _, socket) do
  if end_cursor = socket.assigns.meta.end_cursor do
    {:noreply, push_patch(socket, to: ~p"/pets?after=#{end_cursor}")}
  else
    {:noreply, socket}
  end
end
```

Since the paragraph with the "Load More" link is only shown if there are more
items to show, there won't be any unnecessary events when we reach the end of
the list. The visible and focusable "Load More" button serves as a fallback for
users who rely on keyboard navigation or assistive technologies.

## Final Thoughts

This guide only described a basic implementation of infinite scroll using Flop.
Some details have been omitted, for example:

- If you reload the page with the `after` parameter set, the list will start
  where you left off, but you cannot view the previous items anymore. You might
  want to add another "Load More" button at the top of the list.
- The container should have the
  ["feed" role](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Roles/feed_role), which also has recommended [keyboard interactions](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Roles/feed_role#keyboard_interactions).
- You might want to support the browser's back button.
- You might want to give users the option to disable infinite scrolling.

Apart from the technical side, infinite scroll has a lot of accessibility and
usability issues. It can interfere with assistive technologies, make it
harder to navigate or return to a specific spot, prevent a sense of
progress or place, and reduce user agency.

Before you use infinite scroll, consider whether it's truly the best fit for
your users. In many cases, conventional pagination or the use of a "Load More"
button without infinite scroll can provide a more user-friendly experience.

## Resources

- [Infinite Scrolling & Role=Feed Accessibility Issues](https://www.deque.com/blog/infinite-scrolling-rolefeed-accessibility-issues/)
- [Infinite Scrolling: When to Use It, When to Avoid It](https://www.nngroup.com/articles/infinite-scrolling-tips/)
- [Humane by Design Principles: Finite](https://humanebydesign.com/principles/finite)
- [Infinite Scroll & Accessibility! Is It Any Good?](https://www.digitala11y.com/infinite-scroll-accessibility-is-it-any-good/)
- [OK ARIA! Role=feed is here & it’s not ready for prime time](https://www.digitala11y.com/ok-aria-rolefeed-is-here-its-not-ready-for-prime-time/)
- [So You Think You’ve Built a Good Infinite Scroll](https://adrianroselli.com/2014/05/so-you-think-you-built-good-infinite.html)
