import json
import posixpath
import sys
import yaml
from urllib.parse import urlsplit, urlunsplit
from markdown import Markdown, Extension
from markdown.preprocessors import Preprocessor
from markdown.treeprocessors import Treeprocessor
from typing import List, Tuple
from datetime import datetime

pub_date_format = "%a, %d %b %Y %H:%M:%S %z"
w3c_date_format = "%Y-%m-%d"


class YamlMetadataExtension(Extension):
    def __init__(self, **kwargs):
        self.config = {}
        super().__init__(**kwargs)

    def extendMarkdown(self, md: Markdown, *args, **kwargs) -> None:
        md.registerExtension(self)
        md.Meta = {}  # type: ignore
        md.preprocessors.register(
            YamlMetadataPreprocessor(md, self.getConfigs()), "yaml_metadata", 1
        )


class YamlMetadataPreprocessor(Preprocessor):
    def __init__(self, md, config):
        super().__init__(md)
        self.config = config

    def run(self, lines: List[str]) -> List[str]:
        meta_lines, lines = self.split_by_meta_and_content(lines)

        self.md.Meta = (
            yaml.load("\n".join(meta_lines), Loader=yaml.SafeLoader) or {}
        )
        return lines

    @staticmethod
    def split_by_meta_and_content(
        lines: List[str],
    ) -> Tuple[List[str], List[str]]:
        meta_lines: List[str] = []
        if not lines or lines[0].rstrip(" ") != "---":
            return meta_lines, lines

        lines.pop(0)
        for line in lines:  # type: str
            if line.rstrip(" ") in ("---", "..."):
                content_starts_at = lines.index(line) + 1
                lines = lines[content_starts_at:]
                break

            meta_lines.append(line)

        return meta_lines, lines


class RelativeLinksExtension(Extension):
    """Resolves relative URLs against the source file instead of the page URL.

    Links to Markdown files are rewritten to the URL of their page.
    """

    def __init__(self, page: str, **kwargs):
        self.page = page
        super().__init__(**kwargs)

    def extendMarkdown(self, md: Markdown) -> None:
        md.registerExtension(self)
        # After inline processing and attr_list, so attributes are final.
        md.treeprocessors.register(
            RelativeLinksTreeprocessor(md, self.page), "nixtml_relative_links", 1
        )


def page_dir(name: str) -> str:
    """Directory of a page's output, e.g. `a/b` and `a/b/index` are at `a/b/`."""
    if posixpath.basename(name) == "index":
        return posixpath.dirname(name)
    return name


def rewrite_url(url: str, source_dir: str, output_dir: str) -> str:
    parts = urlsplit(url)
    path = parts.path
    if parts.scheme or parts.netloc or not path or path.startswith("/"):
        return url

    target = posixpath.normpath(posixpath.join(source_dir, path))
    if target == ".." or target.startswith("../"):
        # Outside of the site root, leave it to the author.
        return url

    if target.endswith(".md"):
        target = page_dir(target[:-3])
        if target == "index":
            target = ""
        is_dir = True
    else:
        if target == ".":
            target = ""
        is_dir = path.endswith("/") or target == ""

    rel = posixpath.relpath(target or ".", output_dir or ".")
    if rel == ".":
        rel = "./" if is_dir else rel
    elif is_dir:
        rel += "/"

    return urlunsplit(("", "", rel, parts.query, parts.fragment))


class RelativeLinksTreeprocessor(Treeprocessor):
    def __init__(self, md, page: str):
        super().__init__(md)
        self.source_dir = posixpath.dirname(page)
        self.output_dir = page_dir(page)
        if self.output_dir == "index":
            self.output_dir = ""

    def run(self, root):
        for el in root.iter():
            attr = {"a": "href", "img": "src"}.get(el.tag)
            if attr is None:
                continue
            url = el.get(attr)
            if url is not None:
                el.set(attr, rewrite_url(url, self.source_dir, self.output_dir))


def process_post(post: str, options: dict, page: str) -> str:
    extensions = [YamlMetadataExtension(), *options["extensions"]]
    if options.get("relativeLinks"):
        extensions.append(RelativeLinksExtension(page))

    md = Markdown(
        extensions=extensions,
        extension_configs=options["configs"],
    )
    rendered = md.convert(post)

    # Parse date
    if "date" in md.Meta:
        md.Meta["dateEpoch"] = md.Meta["date"].timestamp()
        md.Meta["dateRFC822"] = md.Meta["date"].strftime(pub_date_format)
        md.Meta["dateW3C"] = md.Meta["date"].strftime(w3c_date_format)

    for k, v in md.Meta.items():
        if isinstance(v, datetime):
            md.Meta[k] = v.strftime(options["dateFormat"])

    return {
        "metadata": md.Meta,
        "content": rendered,
    }


if __name__ == "__main__":
    postPath = sys.argv[1]
    with open(postPath, "r") as f:
        postData = f.read()

    optionsPath = sys.argv[2]
    with open(optionsPath, "r") as f:
        options = json.load(f)

    page = sys.argv[3]

    data = process_post(postData, options, page)

    print(json.dumps(data))
