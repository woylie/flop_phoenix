# CSS Styles

## Pagination

The pagination component doesn't set any default styles. While you can set class
attributes for every element, it is entirely possible to style the component
with just a base class.

```heex
<Flop.Phoenix.pagination class="pagination" ...>
  <%!-- ... --%>
</Flop.Phoenix.pagination>
```

The class above will be set on the `<nav>` element that wraps the pagination
controls. With this in place, we can apply some basic styles. For readability,
we're going to use nested CSS rules in this example.

```css
.pagination {
  display: flex;
  gap: 0.25rem;
  align-items: center;
  justify-content: space-between;

  > ul {
    display: flex;
    flex: 1 1 auto;
    flex-wrap: wrap;
    gap: 0.25rem;
    align-items: center;
    justify-content: flex-end;
    padding: 0;
    margin: 0;
    list-style-type: none;

    li {
      flex: 0 1 auto;
      padding: 0;
      margin: 0;
    }
  }

  > a:first-child,
  > button:first-child {
    flex: none;
  }

  > a:last-of-type,
  > button:last-of-type {
    flex: none;
  }

  a,
  button,
  li > span {
    padding: 0.25rem 0.5rem;
    margin: 0;
    border-radius: 4px;
  }

  li > span {
    color: #00749d;
  }

  a,
  button {
    color: #fff;
    white-space: nowrap;
    background: #00749d;
    border: none;

    &:hover,
    &:focus {
      background-color: #003c54;
    }

    &[aria-current="page"] {
      background-color: #001d2a;
    }
  }

  [disabled],
  [aria-disabled="true"] {
    pointer-events: none;
    opacity: 0.7;
  }
}
```

Let's break this down.

```css
.pagination {
  display: flex;
  gap: 0.25rem;
  align-items: center;
  justify-content: space-between;

  // ...
}
```

This selects the `<nav>` element by using the base class we passed to the
component as an attribute.

```css
> ul {
  display: flex;
  flex: 1 1 auto;
  flex-wrap: wrap;
  gap: 0.25rem;
  align-items: center;
  justify-content: flex-end;
  padding: 0;
  margin: 0;
  list-style-type: none;

  li {
    flex: 0 1 auto;
    padding: 0;
    margin: 0;
  }
}
```

The numbered page links are rendered within an unordered list, which is a
direct descendant of the navigation element.

```css
> a:first-child,
> button:first-child {
  flex: none;
}

> a:last-of-type,
> button:last-of-type {
  flex: none;
}
```

These are styles for the previous link or button (first child) and the next
link or button (last of type). Depending on whether the `path` attribute is
set on the component, Flop.Phoenix will either use `<a>` elements with an `href`
or `<button>` elements to adhere to proper semantics. We need to account for
this in our styles.

```css
a,
button,
li > span {
  padding: 0.25rem 0.5rem;
  margin: 0;
  border-radius: 4px;
}

li > span {
  color: #00749d;
}
```

Here we set some basic styles for the links/buttons (both previous/next and
numbered page links). The `li > span` selector is used to style the ellipsis,
which uses a classless `span` by default.

```css
a,
button {
  color: #fff;
  white-space: nowrap;
  background: #00749d;
  border: none;

  &:hover,
  &:focus {
    background-color: #003c54;
  }

  &[aria-current="page"] {
    background-color: #001d2a;
  }
}
```

Here we set some more styles on the links/buttons, without the ellipsis span.
The pagination component sets the `aria-current` attribute on the page number
link/button to the current page. We can bind our styles to this attributes
without needing a class.

```css
[disabled],
[aria-disabled="true"] {
  pointer-events: none;
  opacity: 0.7;
}
```

Finally, we define styles for disabled previous/next links and buttons. If
buttons are used, the `disabled` attribute is set. Since the `disabled`
attribute cannot be used with links, the `aria-disabled` attribute is set on
`<a>` elements.

### Changing the order

The pagination component will always render the same markup: Individual
previous/next links/buttons first, and then a list with page number
links/buttons. To visually change the order while maintaining the same markup,
you can use the `order` attribute.

To put the page number links/buttons first and the previous/next links/buttons
last:

```css
> a:first-child,
> button:first-child {
  order: 2;
}

> a:last-of-type,
> button:last-of-type {
  order: 3;
}

> ul {
  order: 1;
}
```

To put the page number links/buttons in the middle between the previous
link/button and the next link/button:

```css
> a:first-child,
> button:first-child {
  order: 1;
}

> a:last-of-type,
> button:last-of-type {
  order: 3;
}

> ul {
  order: 2;
}
```

Adjust the remaining flex properties as needed.
