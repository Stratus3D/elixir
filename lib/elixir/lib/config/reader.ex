defmodule Config.Reader do
  @moduledoc """
  API for reading config files defined with `Config`.
  """

  @doc """
  Reads the configuration file.

  The same as `read_with_imports!/2` but only returns the configuration
  in the given file, without returning the imported paths.

  It exists for convenience purposes. For example, you could
  invoke it inside your `mix.exs` to read some external data
  you decided to move to a configuration file:

      releases: Config.Reader.read!("rel/releases.exs")

  """
  @spec read!(Path.t(), [Path.t()]) :: keyword
  def read!(file, imported_paths \\ []) do
    Config.__eval__!(file, imported_paths) |> elem(0)
  end

  @doc """
  Reads the given configuration file.

  It accepts a list of `imported_paths` that should raise if attempted
  to be imported again (to avoid recursive imports).

  It returns a tuple with the configuration and the imported paths.
  """
  @spec read_with_imports!(Path.t(), [Path.t()]) :: {keyword, [Path.t()]}
  def read_with_imports!(file, imported_paths \\ []) do
    Config.__eval__!(file, imported_paths)
  end

  @doc """
  Merges two configurations.

  The configurations are merged together with the values in
  the second one having higher preference than the first in
  case of conflicts. In case both values are set to keyword
  lists, it deep merges them.

  ## Examples

      iex> Config.Reader.merge([app: [k: :v1]], [app: [k: :v2]])
      [app: [k: :v2]]

      iex> Config.Reader.merge([app: [k: [v1: 1, v2: 2]]], [app: [k: [v2: :a, v3: :b]]])
      [app: [k: [v1: 1, v2: :a, v3: :b]]]

      iex> Config.Reader.merge([app1: []], [app2: []])
      [app1: [], app2: []]

  """
  def merge(config1, config2) do
    Config.__merge__(config1, config2)
  end
end
