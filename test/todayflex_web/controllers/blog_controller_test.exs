defmodule TodayflexWeb.BlogControllerTest do
  use TodayflexWeb.ConnCase

  test "GET /blog - lists latest blog posts", %{conn: conn} do
    conn = get conn, Routes.blog_path(conn, :index)

    assert html_response(conn, :ok) =~ "Pretending pencil and paper"
    assert html_response(conn, :ok) =~ Routes.blog_path(conn, :show, "pretending-pencil-and-paper")
  end

  test "GET /blog/:slug - renders an existing blog post", %{conn: conn} do
    conn = get conn, Routes.blog_path(conn, :show, "pretending-pencil-and-paper")
    assert html_response(conn, :ok) =~ "Pretending pencil and paper"
  end

  test "GET /blog/:slug - shows 404 if post is not found", %{conn: conn} do
    conn = get conn, Routes.blog_path(conn, :show, "wrong-slug")
    assert html_response(conn, :not_found)
  end
end
