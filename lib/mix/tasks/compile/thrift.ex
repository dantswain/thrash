defmodule Mix.Tasks.Compile.Thrift do
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
      force_thrift: force_thrift?(System.get_env("FORCE_THRIFT") || nil)
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
