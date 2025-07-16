defmodule MylibrarynewWeb.BookLive.Index do
  use MylibrarynewWeb, :live_view

  alias Mylibrarynew.Library
  alias Mylibrarynew.Library.Book

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :books, Library.list_books())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Book")
    |> assign(:book, Library.get_book!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Book")
    |> assign(:book, %Book{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Books")
    |> assign(:book, nil)
  end

  @impl true
  def handle_info({MylibrarynewWeb.BookLive.FormComponent, {:saved, book}}, socket) do
    {:noreply, stream_insert(socket, :books, book)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    book = Library.get_book!(id)
    {:ok, _} = Library.delete_book(book)

    {:noreply, stream_delete(socket, :books, book)}
  end
end
