defmodule TodayflexWeb.Auth.LoginControllerTest do
  use TodayflexWeb.ConnCase

  test "GET /auth/login - renders the login form", %{conn: conn} do
    conn = get(conn, Routes.auth_login_path(conn, :new))
    assert html_response(conn, 200)
  end

  test "GET /auth/login - redirects to /projects if alreayd logged in", %{conn: conn} do
    register_cats()

    conn = post(conn, Routes.auth_login_path(conn, :create), %{
      email: "cats@todayflex.com",
      password: "1234"
    })

    conn = get(conn, Routes.auth_login_path(conn, :new))
    assert redirected_to(conn) == Routes.project_path(conn, :index)
  end

  test "POST /auth/login - authenticates the session", %{conn: conn} do
    register_cats()

    conn = post(conn, Routes.auth_login_path(conn, :create), %{
      email: "cats@todayflex.com",
      password: "1234"
    })

    assert json_response(conn, 200)
    assert get_session(conn, :user_id)
  end

  test "POST /auth/login - detects incorrect credentials", %{conn: conn} do
    conn = post(conn, Routes.auth_login_path(conn, :create), %{
      email: "wrong@todayflex.com",
      password: "wrong"
    })

    assert json_response(conn, 422)
  end

  defp register_cats do
    Todayflex.Auth.register(%{
      name: "Luiz",
      email: "cats@todayflex.com",
      password: "1234"
    })
  end
end
