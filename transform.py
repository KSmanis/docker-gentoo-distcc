#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path


def _image_registry(image: str) -> str:
    return image.split("/")[0]


def _image_repo(image: str) -> str:
    return image.split(":")[0]


def _image_tag_without_arch(image: str) -> str:
    return "-".join(image.split(":")[-1].split("-")[1:])


def _transform_images(repo: str, image_tag: str, *image_paths: str) -> None:
    print(
        *{
            image
            for image_path in image_paths
            for image in json.loads(Path(image_path).read_bytes())
            if _image_repo(image) == repo
            and _image_tag_without_arch(image) == image_tag
        },
        sep="\n",
    )


def _transform_manifests():
    manifests = []
    for image in os.environ["DOCKER_METADATA_OUTPUT_TAGS"].splitlines():
        for manifest_id in ("latest", "ccache", "ccache_clang", "clang"):
            image_tag = _image_tag_without_arch(image)
            split_image_tag = image_tag.split("-")
            split_image_tag[-1] = manifest_id
            image_tag_with_variant = "-".join(split_image_tag)
            manifests.append(
                {
                    "image_tag": image_tag_with_variant,
                    "manifest_tag": image_tag_with_variant.removesuffix("-latest"),
                    "registry": _image_registry(image),
                    "repo": _image_repo(image),
                }
            )
    print(json.dumps(manifests, separators=(",", ":")), end="")


if __name__ == "__main__":
    match sys.argv[1:]:
        case ["images", repo, image_tag, *image_paths]:
            _transform_images(repo, image_tag, *image_paths)
        case ["manifests"]:
            _transform_manifests()
