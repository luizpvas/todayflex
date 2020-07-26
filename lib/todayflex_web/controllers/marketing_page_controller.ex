defmodule TodayflexWeb.MarketingPageController do
  use TodayflexWeb, :controller

  @doc "GET /"
  def index(conn, _params), do: render(conn, "index.html")

  @doc "GET /about"
  def about(conn, _params), do: render(conn, "about.html")

  @doc "GET /privacy_policy"
  def privacy_policy(conn, _params), do: render(conn, "privacy_policy.html")
end
