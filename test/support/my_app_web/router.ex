defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  scope "/", MyAppWeb do
    get("/pets", PetController, :index)
  end
end
