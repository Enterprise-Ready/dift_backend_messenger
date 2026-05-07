defmodule RideChatWeb.Router do
  use RideChatWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :internal_api do
    plug :accepts, ["json"]
    plug RideChatWeb.Plugs.InternalApiAuth
  end

  scope "/api/internal", RideChatWeb do
    pipe_through :internal_api
    post "/rooms", InternalApiController, :create_room
  end

  scope "/api/v1/chat", RideChatWeb do
    pipe_through :api

    post "/session", SessionController, :create
    get "/rooms/lookup", SessionController, :lookup
    get "/rooms/:id", SessionController, :show
  end
end

