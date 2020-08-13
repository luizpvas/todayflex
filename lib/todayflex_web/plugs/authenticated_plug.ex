defmodule TodayflexWeb.AuthenticatedPlug do
  import Plug.Conn
  alias TodayflexWeb.Router.Helpers, as: Routes

  def init(args), do: args

  def call(conn, _args) do
    case get_session(conn, :user_id) do
      nil ->
        conn
        |> Phoenix.Controller.redirect(to: Routes.auth_login_path(conn, :new))
        |> halt()

      user_id ->
        # TODO: get the current user
        conn
    end
  end
end
