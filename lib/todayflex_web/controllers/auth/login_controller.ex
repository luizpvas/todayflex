defmodule TodayflexWeb.Auth.LoginController do
  use TodayflexWeb, :controller
  plug :redirect_to_dashboard_if_already_logged_in when action in [:new, :create]

  @doc """
  GET /auth/login

  Shows the login form
  """
  def new(conn, _params) do
    render(conn, "new.html")
  end

  @doc """
  POST /auth/login

  Attempts to login with the given credentials
  """
  def create(conn, params) do
    case Todayflex.Auth.authenticate(params["email"], params["password"]) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> json(%{"status" => "ok"})

      {:error, :incorrect_email} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{"error" => "incorrect_email"})

      {:error, :incorrect_password} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{"error" => "incorrect_password"})
    end
  end

  defp redirect_to_dashboard_if_already_logged_in(conn, _params) do
    case get_session(conn, :user_id) do
      nil      -> conn
      _not_nil -> conn |> redirect(to: Routes.project_path(conn, :index)) |> halt()
    end
  end
end
