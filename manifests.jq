.tags | map(
  {
    image_tag: split(":")[-1],
    registry: split("/")[0],
    repo: split(":")[0]
  } | [
    (.image_tag |= sub("^\($tag_prefix)"; "latest") | .manifest_tag = (.image_tag | ltrimstr("latest-"))),
    (.image_tag |= sub("^\($tag_prefix)"; "ccache") | .manifest_tag = (.image_tag | ltrimstr("latest-")))
  ]
) | flatten
