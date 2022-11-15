defmodule MyAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :flop_phoenix

  plug(MyAppWeb.Router)
end
