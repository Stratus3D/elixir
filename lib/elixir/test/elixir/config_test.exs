Code.require_file("test_helper.exs", __DIR__)

defmodule ConfigTest do
  use ExUnit.Case, async: true

  doctest Config
  doctest Config.Reader

  import Config
  import PathHelpers

  setup do
    Process.put({Config, :config}, [])
    Process.put({Config, :files}, [])
    :ok
  end

  defp config do
    Process.get({Config, :config})
  end

  defp files do
    Process.get({Config, :files})
  end

  test "config/2" do
    assert config() == []

    config :lager, key: :value
    assert config() == [lager: [key: :value]]

    config :lager, other: :value
    assert config() == [lager: [key: :value, other: :value]]

    config :lager, key: :other
    assert config() == [lager: [other: :value, key: :other]]

    # Works inside functions too...
    f = fn -> config(:lager, key: :fn) end
    f.()
    assert config() == [lager: [other: :value, key: :fn]]

    # ...and in for comprehensions.
    for _ <- 0..0, do: config(:lager, key: :for)
    assert config() == [lager: [other: :value, key: :for]]
  end

  test "config/3" do
    config :app, Repo, key: :value
    assert config() == [app: [{Repo, key: :value}]]

    config :app, Repo, other: :value
    assert config() == [app: [{Repo, key: :value, other: :value}]]

    config :app, Repo, key: :other
    assert config() == [app: [{Repo, other: :value, key: :other}]]

    config :app, Repo, key: [nested: false]
    assert config() == [app: [{Repo, other: :value, key: [nested: false]}]]

    config :app, Repo, key: [nested: true]
    assert config() == [app: [{Repo, other: :value, key: [nested: true]}]]

    config :app, Repo, key: :other
    assert config() == [app: [{Repo, other: :value, key: :other}]]
  end

  test "import_config/1" do
    import_config fixture_path("configs/good_config.exs")
    assert config() == [my_app: [key: :value]]
    assert files() == [fixture_path("configs/good_config.exs")]
  end

  test "import_config/1 raises for recursive import" do
    assert_raise ArgumentError,
                 ~r"attempting to load configuration .*/imports_recursive.exs recursively",
                 fn -> import_config fixture_path("configs/imports_recursive.exs") end
  end

  test "import_config/1 with nested" do
    config :app, Repo, key: [nested: false, other: true]
    import_config fixture_path("configs/nested.exs")
    assert config() == [app: [{Repo, key: [other: true, nested: true]}]]
  end

  test "import_config/1 with bad path" do
    assert_raise Code.LoadError, ~r"could not load .*/configs/unknown.exs", fn ->
      import_config fixture_path("configs/unknown.exs")
    end
  end

  describe "Reader" do
    test "read_with_imports!/2" do
      assert Config.Reader.read_with_imports!(fixture_path("configs/good_kw.exs")) ==
               {[my_app: [key: :value]], [fixture_path("configs/good_kw.exs")]}

      assert Config.Reader.read_with_imports!(fixture_path("configs/good_config.exs")) ==
               {[my_app: [key: :value]], [fixture_path("configs/good_config.exs")]}

      assert Config.Reader.read_with_imports!(fixture_path("configs/good_import.exs")) ==
               {[my_app: [key: :value]],
                [fixture_path("configs/good_config.exs"), fixture_path("configs/good_import.exs")]}

      assert Config.Reader.read_with_imports!(fixture_path("configs/nested_import.exs")) ==
               {[], [fixture_path("configs/nested_import.exs")]}

      assert_raise ArgumentError,
                   ~r"expected config for app :sample in .*/bad_app.exs to return keyword list",
                   fn -> Config.Reader.read_with_imports!(fixture_path("configs/bad_app.exs")) end

      assert_raise Code.LoadError,
                   fn ->
                     Config.Reader.read_with_imports!(fixture_path("configs/bad_root.exs"))
                   end

      assert_raise Code.LoadError,
                   fn ->
                     Config.Reader.read_with_imports!(fixture_path("configs/bad_import.exs"))
                   end
    end

    test "read!/2" do
      assert Config.Reader.read!(fixture_path("configs/good_kw.exs")) ==
               [my_app: [key: :value]]

      assert Config.Reader.read!(fixture_path("configs/good_config.exs")) ==
               [my_app: [key: :value]]

      assert Config.Reader.read!(fixture_path("configs/good_import.exs")) ==
               [my_app: [key: :value]]
    end
  end
end
