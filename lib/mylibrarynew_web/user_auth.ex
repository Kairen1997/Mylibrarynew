defmodule MylibrarynewWeb.UserAuth do
  import Plug.Conn

  # This plug assigns the current user to the connection if found in the session.
  def fetch_current_user(conn, _opts) do
    # TODO: Replace this with real session/token lookup logic
    assign(conn, :current_user, nil)
  end
end
