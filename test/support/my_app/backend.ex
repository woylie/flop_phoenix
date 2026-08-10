defmodule MyApp.Backend do
  @moduledoc """
  Defines a Flop backend module for testing.
  """
  use Flop, repo: MyApp.Repo, default_limit: 25, max_limit: 50
end
