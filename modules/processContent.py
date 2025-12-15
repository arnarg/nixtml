import json
import sys
import yaml
from markdown import Markdown, Extension
from markdown.preprocessors import Preprocessor
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
        md.Meta = None  # type: ignore
        md.preprocessors.register(
            YamlMetadataPreprocessor(md, self.getConfigs()), "yaml_metadata", 1
        )


class YamlMetadataPreprocessor(Preprocessor):
    def __init__(self, md, config):
        super().__init__(md)
        self.config = config

    def run(self, lines: List[str]) -> List[str]:
        meta_lines, lines = self.split_by_meta_and_content(lines)

        self.md.Meta = yaml.load("\n".join(meta_lines), Loader=yaml.SafeLoader)
        return lines

    @staticmethod
    def split_by_meta_and_content(
        lines: List[str],
    ) -> Tuple[List[str], List[str]]:
        meta_lines: List[str] = []
        if lines[0].rstrip(" ") != "---":
            return meta_lines, lines

        lines.pop(0)
        for line in lines:  # type: str
            if line.rstrip(" ") in ("---", "..."):
                content_starts_at = lines.index(line) + 1
                lines = lines[content_starts_at:]
                break

            meta_lines.append(line)

        return meta_lines, lines


def process_post(post: str, options: dict) -> str:
    md = Markdown(
        extensions=[
            YamlMetadataExtension(),
            "tables",
            "footnotes",
            "toc",
            "pymdownx.superfences",
            "pymdownx.highlight",
            "pymdownx.blocks.admonition",
            "pymdownx.inlinehilite",
            "pymdownx.magiclink",
        ],
        extension_configs={
            "toc": {
                "marker": options["toc"]["marker"],
                "title": options["toc"]["title"],
                "title_class": options["toc"]["titleClass"],
                "toc_class": options["toc"]["tocClass"],
                "anchorlink": options["toc"]["anchorlink"],
                "anchorlink_class": options["toc"]["anchorlinkClass"],
                "permalink": options["toc"]["permalink"],
                "permalink_class": options["toc"]["permalinkClass"],
            },
            "pymdownx.highlight": {
                "noclasses": True,
                "use_pygments": True,
                "pygments_style": options["highlight"]["style"],
            },
        },
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

    data = process_post(postData, options)

    print(json.dumps(data))
