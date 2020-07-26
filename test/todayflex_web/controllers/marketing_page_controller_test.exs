defmodule TodayflexWeb.MarketingPageControllerTest do
  use TodayflexWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200)
  end

  test "GET /about", %{conn: conn} do
    conn = get(conn, "/about")
    assert html_response(conn, 200)
  end

  test "GET /privacy_policy", %{conn: conn} do
    conn = get(conn, "/privacy_policy")
    assert html_response(conn, 200)
  end
end
