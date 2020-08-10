defmodule TodayflexWeb.BlogController do
  use TodayflexWeb, :controller
  alias Todayflex.Blog

  def index(conn, _params) do
    posts = Blog.latest_posts(10)
    render(conn, "index.html", posts: posts)
  end

  def show(conn, %{"slug" => slug}) do
    with {:ok, post} <- Blog.find_post(slug) do
      render(conn, "show.html", post: post)
    end
  end
end
