defmodule TodayflexWeb.ProjectController do
  use TodayflexWeb, :controller

  @doc """
  GET /editor
  This page boots an SPA written in elm (see assets/elm).
  """
  def show(conn, %{"id" => project_id}) do
    project = Todayflex.Repo.get!(Todayflex.Auth.Project, project_id)
    render(conn, "show.html", project: project)
  end
end
