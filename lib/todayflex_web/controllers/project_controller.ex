defmodule TodayflexWeb.ProjectController do
  use TodayflexWeb, :controller
  alias Todayflex.Project.Project

  @doc """
  GET /projects

  Lists projects the current user is a member
  """
  def index(conn, _params) do
    render(conn, "index.html")
  end

  @doc """
  GET /editor
  This page boots an SPA written in elm (see assets/elm).
  """
  def show(conn, %{"id" => project_id}) do
    project = Todayflex.Repo.get!(Todayflex.Auth.Project, project_id)
    render(conn, "show.html", project: project)
  end

  @doc """
  GET /projects/new

  Shows the new project form.
  """
  def new(conn, _params) do
    render(conn, "new.html")
  end

  @doc """
  POST /projects

  Attempts to create a new form
  """
  def create(conn, params) do
  end
end
