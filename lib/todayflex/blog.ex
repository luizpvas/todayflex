defmodule Todayflex.Blog do
  @moduledoc """
  The blog system works a veeery simple way.

  * Posts are markdown files located in priv/blog.
  * Post files are prefixed with a number that describes the order, such as "01-pen-and-paper.md"
  * Url slugs are the file name minus the number prefix and the ".md" extension, so that
    "01-pen-and-paper.md" would be "/blog/pen-and-paper" in the url.
  """

  def latest_posts(n \\ 10) do
    read_posts_files_from_disk()
    |> Enum.take(n)
  end

  def find_post(slug) do
    read_posts_files_from_disk()
    |> Enum.filter(fn post -> post[:slug] == slug end)
    |> List.first()
    |> case do
      nil -> {:error, :not_found}
      post -> {:ok, post}
    end
  end

  defp read_posts_files_from_disk do
    blog_posts_path()
    |> File.ls!()
    |> Enum.map(&Path.join(blog_posts_path(), &1))
    |> Enum.map(&parse_post_metadata/1)
  end

  defp parse_post_metadata(abs_filepath) do
    markdown = File.read!(abs_filepath)

    post = parse_post(markdown)

    Map.merge(post, %{
      slug: slug_from_abs_filepath(abs_filepath),
      abs_filepath: abs_filepath
    })
  end

  defp blog_posts_path do
    Path.join(:code.priv_dir(:todayflex), "blog")
  end

  defp slug_from_abs_filepath(abs_filepath) do
    Path.basename(abs_filepath, ".md")
    |> String.split("-")
    |> Enum.drop(1)
    |> Enum.join("-")
  end

  defp parse_post(markdown) do
    [title, author, date | markdown] = String.split(markdown, "\n")

    preview =
      markdown
      |> Enum.filter(fn line -> line |> String.trim() |> String.length() > 0 end)
      |> Enum.take(3)
      |> Enum.join(" ")
      |> String.slice(0..100)

    html = Earmark.as_html!(markdown)

    %{
      title: title,
      author: author,
      date: date,
      preview: preview <> "...",
      html: html
    }
  end
end
