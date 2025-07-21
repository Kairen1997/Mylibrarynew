defmodule MylibrarynewWeb.Router do
  use MylibrarynewWeb, :router

  import MylibrarynewWeb.CredentialAuth
  import MylibrarynewWeb.UserAuth


  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MylibrarynewWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_credential
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MylibrarynewWeb do
    pipe_through :browser

    get "/", PageController, :home

    live "/users", UserLive.Index, :index
    live "/users/new", UserLive.Index, :new
    live "/users/:id/edit", UserLive.Index, :edit

    live "/users/:id", UserLive.Show, :show
    live "/users/:id/show/edit", UserLive.Show, :edit


    live "/books", BookLive.Index, :index
    live "/books/new", BookLive.Index, :new
    live "/books/:id/edit", BookLive.Index, :edit

    live "/books/:id", BookLive.Show, :show
    live "/books/:id/show/edit", BookLive.Show, :edit

    live "/loans", LoanLive.Index, :index
    live "/loans/new", LoanLive.Index, :new
    live "/loans/:id/edit", LoanLive.Index, :edit

    live "/loans/:id", LoanLive.Show, :show
    live "/loans/:id/show/edit", LoanLive.Show, :edit

  end

  ## Authentication routes

  scope "/", MylibrarynewWeb do
    pipe_through [:browser, :redirect_if_credential_is_authenticated]

    live_session :redirect_if_credential_is_authenticated,
      on_mount: [{MylibrarynewWeb.CredentialAuth, :redirect_if_credential_is_authenticated}] do
      live "/credentials/register", CredentialRegistrationLive, :new
      live "/credentials/log_in", CredentialLoginLive, :new
      live "/credentials/reset_password", CredentialForgotPasswordLive, :new
      live "/credentials/reset_password/:token", CredentialResetPasswordLive, :edit
    end

    post "/credentials/log_in", CredentialSessionController, :create
  end

  scope "/", MylibrarynewWeb do
    pipe_through [:browser, :require_authenticated_credential]

    live_session :require_authenticated_credential,
      on_mount: [{MylibrarynewWeb.CredentialAuth, :ensure_authenticated}] do
      live "/credentials/settings", CredentialSettingsLive, :edit
      live "/credentials/settings/confirm_email/:token", CredentialSettingsLive, :confirm_email
    end
  end

  scope "/", MylibrarynewWeb do
    pipe_through [:browser]

    delete "/credentials/log_out", CredentialSessionController, :delete

    live_session :current_credential,
      on_mount: [{MylibrarynewWeb.CredentialAuth, :mount_current_credential}] do
      live "/credentials/confirm/:token", CredentialConfirmationLive, :edit
      live "/credentials/confirm", CredentialConfirmationInstructionsLive, :new
    end
  end
end
