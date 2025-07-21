defmodule MylibrarynewWeb.CredentialAuthTest do
  use MylibrarynewWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias Mylibrarynew.Authentication
  alias MylibrarynewWeb.CredentialAuth
  import Mylibrarynew.AuthenticationFixtures

  @remember_me_cookie "_mylibrarynew_web_credential_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, MylibrarynewWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{credential: credential_fixture(), conn: conn}
  end

  describe "log_in_credential/3" do
    test "stores the credential token in the session", %{conn: conn, credential: credential} do
      conn = CredentialAuth.log_in_credential(conn, credential)
      assert token = get_session(conn, :credential_token)
      assert get_session(conn, :live_socket_id) == "credentials_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/"
      assert Authentication.get_credential_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, credential: credential} do
      conn = conn |> put_session(:to_be_removed, "value") |> CredentialAuth.log_in_credential(credential)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, credential: credential} do
      conn = conn |> put_session(:credential_return_to, "/hello") |> CredentialAuth.log_in_credential(credential)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, credential: credential} do
      conn = conn |> fetch_cookies() |> CredentialAuth.log_in_credential(credential, %{"remember_me" => "true"})
      assert get_session(conn, :credential_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :credential_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_credential/1" do
    test "erases session and cookies", %{conn: conn, credential: credential} do
      credential_token = Authentication.generate_credential_session_token(credential)

      conn =
        conn
        |> put_session(:credential_token, credential_token)
        |> put_req_cookie(@remember_me_cookie, credential_token)
        |> fetch_cookies()
        |> CredentialAuth.log_out_credential()

      refute get_session(conn, :credential_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute Authentication.get_credential_by_session_token(credential_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "credentials_sessions:abcdef-token"
      MylibrarynewWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> CredentialAuth.log_out_credential()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if credential is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> CredentialAuth.log_out_credential()
      refute get_session(conn, :credential_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "fetch_current_credential/2" do
    test "authenticates credential from session", %{conn: conn, credential: credential} do
      credential_token = Authentication.generate_credential_session_token(credential)
      conn = conn |> put_session(:credential_token, credential_token) |> CredentialAuth.fetch_current_credential([])
      assert conn.assigns.current_credential.id == credential.id
    end

    test "authenticates credential from cookies", %{conn: conn, credential: credential} do
      logged_in_conn =
        conn |> fetch_cookies() |> CredentialAuth.log_in_credential(credential, %{"remember_me" => "true"})

      credential_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> CredentialAuth.fetch_current_credential([])

      assert conn.assigns.current_credential.id == credential.id
      assert get_session(conn, :credential_token) == credential_token

      assert get_session(conn, :live_socket_id) ==
               "credentials_sessions:#{Base.url_encode64(credential_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, credential: credential} do
      _ = Authentication.generate_credential_session_token(credential)
      conn = CredentialAuth.fetch_current_credential(conn, [])
      refute get_session(conn, :credential_token)
      refute conn.assigns.current_credential
    end
  end

  describe "on_mount :mount_current_credential" do
    test "assigns current_credential based on a valid credential_token", %{conn: conn, credential: credential} do
      credential_token = Authentication.generate_credential_session_token(credential)
      session = conn |> put_session(:credential_token, credential_token) |> get_session()

      {:cont, updated_socket} =
        CredentialAuth.on_mount(:mount_current_credential, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_credential.id == credential.id
    end

    test "assigns nil to current_credential assign if there isn't a valid credential_token", %{conn: conn} do
      credential_token = "invalid_token"
      session = conn |> put_session(:credential_token, credential_token) |> get_session()

      {:cont, updated_socket} =
        CredentialAuth.on_mount(:mount_current_credential, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_credential == nil
    end

    test "assigns nil to current_credential assign if there isn't a credential_token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} =
        CredentialAuth.on_mount(:mount_current_credential, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_credential == nil
    end
  end

  describe "on_mount :ensure_authenticated" do
    test "authenticates current_credential based on a valid credential_token", %{conn: conn, credential: credential} do
      credential_token = Authentication.generate_credential_session_token(credential)
      session = conn |> put_session(:credential_token, credential_token) |> get_session()

      {:cont, updated_socket} =
        CredentialAuth.on_mount(:ensure_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_credential.id == credential.id
    end

    test "redirects to login page if there isn't a valid credential_token", %{conn: conn} do
      credential_token = "invalid_token"
      session = conn |> put_session(:credential_token, credential_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: MylibrarynewWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = CredentialAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_credential == nil
    end

    test "redirects to login page if there isn't a credential_token", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: MylibrarynewWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = CredentialAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_credential == nil
    end
  end

  describe "on_mount :redirect_if_credential_is_authenticated" do
    test "redirects if there is an authenticated  credential ", %{conn: conn, credential: credential} do
      credential_token = Authentication.generate_credential_session_token(credential)
      session = conn |> put_session(:credential_token, credential_token) |> get_session()

      assert {:halt, _updated_socket} =
               CredentialAuth.on_mount(
                 :redirect_if_credential_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end

    test "doesn't redirect if there is no authenticated credential", %{conn: conn} do
      session = conn |> get_session()

      assert {:cont, _updated_socket} =
               CredentialAuth.on_mount(
                 :redirect_if_credential_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end
  end

  describe "redirect_if_credential_is_authenticated/2" do
    test "redirects if credential is authenticated", %{conn: conn, credential: credential} do
      conn = conn |> assign(:current_credential, credential) |> CredentialAuth.redirect_if_credential_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "does not redirect if credential is not authenticated", %{conn: conn} do
      conn = CredentialAuth.redirect_if_credential_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_credential/2" do
    test "redirects if credential is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> CredentialAuth.require_authenticated_credential([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/credentials/log_in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> CredentialAuth.require_authenticated_credential([])

      assert halted_conn.halted
      assert get_session(halted_conn, :credential_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> CredentialAuth.require_authenticated_credential([])

      assert halted_conn.halted
      assert get_session(halted_conn, :credential_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> CredentialAuth.require_authenticated_credential([])

      assert halted_conn.halted
      refute get_session(halted_conn, :credential_return_to)
    end

    test "does not redirect if credential is authenticated", %{conn: conn, credential: credential} do
      conn = conn |> assign(:current_credential, credential) |> CredentialAuth.require_authenticated_credential([])
      refute conn.halted
      refute conn.status
    end
  end
end
