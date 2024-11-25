defmodule Fastmail.Contacts.CardsResponse do
  alias Fastmail.Contacts.Card

  defstruct [:body]

  def new(body) do
    %__MODULE__{body: body}
  end

  def parse(%__MODULE__{body: body}) do
    lines(body)
    |> Enum.reduce([], &group_lines_by_vcard/2)
    |> Enum.reverse()
    |> Enum.map(&Card.new/1)
  end

  defp group_lines_by_vcard(line, vcard_lines) do
    dbg(line)

    case line do
      "BEGIN:VCARD" ->
        [[] | vcard_lines]

      "END:VCARD" ->
        vcard_lines

      _ ->
        current_card = hd(vcard_lines)
        [[line | current_card] | tl(vcard_lines)]
    end
  end

  defp lines(body) do
    String.split(body, "\r\n")
    |> Enum.reject(fn line -> String.trim(line) == "" end)
    |> combine_folded_lines()
  end

  defp combine_folded_lines([]), do: []

  defp combine_folded_lines([last_line]), do: [last_line]

  defp combine_folded_lines([current_line | tail]) do
    case hd(tail) do
      " " <> next_line ->
        folded_line = current_line <> next_line
        combine_folded_lines([folded_line | tl(tail)])

      _ ->
        [current_line | combine_folded_lines(tail)]
    end
  end
end
