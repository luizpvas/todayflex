defmodule TodayflexWeb.UI.ButtonView do
  def button_link(args, do: block) do
    args
    |> Keyword.put(:class, "bg-blue-500 text-blue-100 py-1 px-2 font-bold rounded-md border border-blue-600 flex items-center space-x-1 shadow-sm")
    |> Phoenix.HTML.Link.link(do: block)
  end
end
