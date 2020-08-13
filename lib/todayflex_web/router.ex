defmodule TodayflexWeb.Router do
  use TodayflexWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :authenticated do
    plug TodayflexWeb.AuthenticatedPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TodayflexWeb do
    pipe_through :browser

    # Public/Marketing routes
    get "/",               MarketingPageController, :index
    get "/about",          MarketingPageController, :about
    get "/privacy_policy", MarketingPageController, :privacy_policy
    get "/blog",           BlogController,          :index
    get "/blog/:slug",     BlogController,          :show

    # Auth routes
    scope "/auth", Auth, as: :auth do
      get  "/login", LoginController, :new
      post "/login", LoginController, :create
    end

    scope "/app" do
      pipe_through :authenticated

      get  "/projects",                         ProjectController,        :index
      get  "/projects/:id",                     ProjectController,        :show
      get  "/projects/:project_id/widgets",     Project.WidgetController, :index
      post "/projects/:project_id/widgets",     Project.WidgetController, :create
      put  "/projects/:project_id/widgets/:id", Project.WidgetController, :update
    end
  end

  # Other scopes may use custom stacks.
  scope "/api", TodayflexWeb do
    pipe_through :api
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: TodayflexWeb.Telemetry
    end
  end
end
