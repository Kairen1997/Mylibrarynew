defmodule Mylibrarynew.LibraryTest do
  use Mylibrarynew.DataCase

  alias Mylibrarynew.Library

  describe "books" do
    alias Mylibrarynew.Library.Book

    import Mylibrarynew.LibraryFixtures

    @invalid_attrs %{title: nil, author: nil, isbn: nil, publised_at: nil}

    test "list_books/0 returns all books" do
      book = book_fixture()
      assert Library.list_books() == [book]
    end

    test "get_book!/1 returns the book with given id" do
      book = book_fixture()
      assert Library.get_book!(book.id) == book
    end

    test "create_book/1 with valid data creates a book" do
      valid_attrs = %{title: "some title", author: "some author", isbn: "some isbn", publised_at: ~D[2025-07-15]}

      assert {:ok, %Book{} = book} = Library.create_book(valid_attrs)
      assert book.title == "some title"
      assert book.author == "some author"
      assert book.isbn == "some isbn"
      assert book.publised_at == ~D[2025-07-15]
    end

    test "create_book/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Library.create_book(@invalid_attrs)
    end

    test "update_book/2 with valid data updates the book" do
      book = book_fixture()
      update_attrs = %{title: "some updated title", author: "some updated author", isbn: "some updated isbn", publised_at: ~D[2025-07-16]}

      assert {:ok, %Book{} = book} = Library.update_book(book, update_attrs)
      assert book.title == "some updated title"
      assert book.author == "some updated author"
      assert book.isbn == "some updated isbn"
      assert book.publised_at == ~D[2025-07-16]
    end

    test "update_book/2 with invalid data returns error changeset" do
      book = book_fixture()
      assert {:error, %Ecto.Changeset{}} = Library.update_book(book, @invalid_attrs)
      assert book == Library.get_book!(book.id)
    end

    test "delete_book/1 deletes the book" do
      book = book_fixture()
      assert {:ok, %Book{}} = Library.delete_book(book)
      assert_raise Ecto.NoResultsError, fn -> Library.get_book!(book.id) end
    end

    test "change_book/1 returns a book changeset" do
      book = book_fixture()
      assert %Ecto.Changeset{} = Library.change_book(book)
    end
  end

  describe "loans" do
    alias Mylibrarynew.Library.Loan

    import Mylibrarynew.LibraryFixtures

    @invalid_attrs %{borrowed_at: nil, due_at: nil, returned_at: nil}

    test "list_loans/0 returns all loans" do
      loan = loan_fixture()
      assert Library.list_loans() == [loan]
    end

    test "get_loan!/1 returns the loan with given id" do
      loan = loan_fixture()
      assert Library.get_loan!(loan.id) == loan
    end

    test "create_loan/1 with valid data creates a loan" do
      valid_attrs = %{borrowed_at: ~N[2025-07-15 03:43:00], due_at: ~N[2025-07-15 03:43:00], returned_at: ~N[2025-07-15 03:43:00]}

      assert {:ok, %Loan{} = loan} = Library.create_loan(valid_attrs)
      assert loan.borrowed_at == ~N[2025-07-15 03:43:00]
      assert loan.due_at == ~N[2025-07-15 03:43:00]
      assert loan.returned_at == ~N[2025-07-15 03:43:00]
    end

    test "create_loan/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Library.create_loan(@invalid_attrs)
    end

    test "update_loan/2 with valid data updates the loan" do
      loan = loan_fixture()
      update_attrs = %{borrowed_at: ~N[2025-07-16 03:43:00], due_at: ~N[2025-07-16 03:43:00], returned_at: ~N[2025-07-16 03:43:00]}

      assert {:ok, %Loan{} = loan} = Library.update_loan(loan, update_attrs)
      assert loan.borrowed_at == ~N[2025-07-16 03:43:00]
      assert loan.due_at == ~N[2025-07-16 03:43:00]
      assert loan.returned_at == ~N[2025-07-16 03:43:00]
    end

    test "update_loan/2 with invalid data returns error changeset" do
      loan = loan_fixture()
      assert {:error, %Ecto.Changeset{}} = Library.update_loan(loan, @invalid_attrs)
      assert loan == Library.get_loan!(loan.id)
    end

    test "delete_loan/1 deletes the loan" do
      loan = loan_fixture()
      assert {:ok, %Loan{}} = Library.delete_loan(loan)
      assert_raise Ecto.NoResultsError, fn -> Library.get_loan!(loan.id) end
    end

    test "change_loan/1 returns a loan changeset" do
      loan = loan_fixture()
      assert %Ecto.Changeset{} = Library.change_loan(loan)
    end
  end
end
