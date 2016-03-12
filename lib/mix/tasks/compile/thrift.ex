defmodule Mix.Tasks.Compile.Thrift do
  @moduledoc """
  Provides a mix task for compiling Thrift IDL files to Erlang.

  Once Thrash is
  compiled, you can execute `mix compile.thrift` to generate Erlang code
  (a required precursor for Thrash) from your Thrift IDL files (i.e.,
  `.thrift` files).  By default, `mix compile.thrift` assumes that your
  IDL files are in the `thrift` directory and that the output should go
  in the `src` directory. 

  The following environment variables modify the behavior of `mix
  compile.thrift`.

  * `THRIFT` - Path to the `thrift` binary (default: `thrift`).
  * `THRIFT_INPUT_DIR` - Directory containing your `.thrift` files
    (default: `thrift`).
  * `THRIFT_OUTPUT_DIR` - Directory in which generated Erlang
    source code is placed (default: `src`).
  * `FORCE_THRIFT` - Set to any of `["TRUE", "true", "1"]` to force
    execution of `thrift`.  By default, the task automatically determines
    if it is necessary to execute `thrift` based on the mtimes of the
    files in the input and output directories.

  Prepend `:thrift` to the list of compilers in your project
  and this task will run automatically as needed.

  ```
  defmodule MyProject.Mixfile do
    use Mix.Project
    
    def project do
      [app: :my_project,
      # usual stuff ..

      # prepend thrift to the usual list of compilers
      compilers: [:thrift] ++ Mix.compilers

      # ...
      ]
    end
  end
  ```

  Run `mix deps.compile` first to ensure that the `compile.thrift` task
  is available.
  """

  use Mix.Task

  def run(_args) do
    options = get_env_options()

    File.mkdir_p!(options[:thrift_output_dir])

    input_files = thrift_files(options[:thrift_input_dir])
    output_files = generated_files(options[:thrift_output_dir])
    
    if require_compile?(options[:force_thrift], input_files, output_files) do
      run_thrift(options[:thrift],
                 options[:thrift_input_dir],
                 options[:thrift_output_dir])
    end
  end

  defp get_env_options() do
    %{
      thrift: System.get_env("THRIFT") || "thrift",
      thrift_input_dir: System.get_env("THRIFT_INPUT_DIR") || "thrift",
      thrift_output_dir: System.get_env("THRIFT_OUTPUT_DIR") || "src",
      force_thrift: force_thrift?(System.get_env("FORCE_THRIFT") || false)
    }
  end

  defp thrift_files(thrift_input_dir) do
    Mix.Utils.extract_files([thrift_input_dir], ["thrift"])
  end

  defp run_thrift_on(f, thrift_bin, thrift_output_dir) do
    cmd = thrift_bin <> " -o #{thrift_output_dir} --gen erl #{f}"
    IO.puts cmd
    0 = Mix.shell.cmd(cmd)
  end

  defp run_thrift(thrift_bin, thrift_input_dir, thrift_output_dir) do
    thrift_files(thrift_input_dir)
    |> Enum.each(fn(f) -> run_thrift_on(f, thrift_bin, thrift_output_dir) end)
  end

  defp generated_files(output_dir) do
    Mix.Utils.extract_files([Path.join(output_dir, "gen-erl")], ["hrl", "erl"])
  end

  defp force_thrift?("TRUE"), do: true
  defp force_thrift?("true"), do: true
  defp force_thrift?("1"), do: true
  defp force_thrift?(_), do: false

  defp require_compile?(true, _, _), do: true
  defp require_compile?(false, _, []), do: true
  defp require_compile?(false, input_files, output_files) do
    input_stats = stats_by_mtime(input_files)
    output_stats = stats_by_mtime(output_files)

    most_recent(input_stats) > least_recent(output_stats)
  end

  defp stats_by_mtime(files) do
    Enum.sort_by(file_stats(files), fn(stat) -> stat.mtime end)
  end

  defp file_stats(files) do
    Enum.map(files, fn(file) ->
      File.stat!(file, time: :posix)
    end)
  end

  defp most_recent([]), do: 0
  defp most_recent([h | _t]), do: h.mtime

  # note x < :infinity is true for any integer
  defp least_recent([]), do: :infinity
  defp least_recent(list) do
    last = List.last(list)
    last.mtime
  end
end
