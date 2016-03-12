defmodule Mix.Tasks.Compile.Thrift do
  use Mix.Task

  def run(_args) do
    IO.puts("I AM RUNNING THE MIX COMPILE TASK")
    options = get_env_options()

    File.mkdir_p!(options[:thrift_output_dir])
    run_thrift(options[:thrift],
               options[:thrift_input_dir],
               options[:thrift_output_dir])
  end

  defp get_env_options() do
    %{
      thrift: System.get_env("THRIFT") || "thrift",
      thrift_input_dir: System.get_env("THRIFT_INPUT_DIR") || "thrift",
      thrift_output_dir: System.get_env("THRIFT_OUTPUT_DIR") || "src"
    }
  end

  defp thrift_files(thrift_input_dir) do
    Mix.Utils.extract_files([thrift_input_dir], "*.thrift")
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
end
