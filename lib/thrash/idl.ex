defmodule Thrash.IDL do
  def parse do
    parse(Application.get_env(:thrash, :idl_files))
  end

  def parse(junk) when junk == [] or is_nil(junk) do
    raise ArgumentError, message: "No IDL files found."
  end
  def parse(idl_files) do
    idl_files
    |> Enum.reduce(%Thrift.Parser.Models.Schema{}, fn(path, full_schema) ->
      file_idl = Thrift.Parser.parse(File.read!(path))
      merge(full_schema, file_idl)
    end)
  end

  def merge(
    accum = %Thrift.Parser.Models.Schema{},
    el = %Thrift.Parser.Models.Schema{}) do
    %{accum |
      constants: merge_maps(accum.constants, el.constants),
      enums: merge_maps(accum.enums, el.enums),
      exceptions: merge_maps(accum.exceptions, el.exceptions),
      includes: merge_includes(accum.includes, el.includes),
      namespaces: merge_maps(accum.namespaces, el.namespaces),
      services: merge_maps(accum.services, el.services),
      structs: merge_maps(accum.structs, el.structs),
      thrift_namespace: merge_namespaces(accum.thrift_namespace, el.thrift_namespace),
      typedefs: merge_maps(accum.typedefs, el.typedefs),
      unions: merge_maps(accum.unions, el.unions)
    }
  end

  defp merge_maps(m1, m2) do
    Map.merge(m1, m2)
  end

  defp merge_includes(i1, i2) do
    i1 ++ i2
  end

  defp merge_namespaces(nil, nil), do: nil
  defp merge_namespaces(s1, s2) do
    IO.puts("NAMESPACES: #{inspect s1} #{inspect s2}")
    s2
  end
end
