.tags | map(
  {
    image_tag: (split(":")[-1] | split("-")[1:] | join("-")),
    registry: split("/")[0],
    repo: split(":")[0]
  } | [
    (.image_tag |= sub("(?<prefix>^|-)[^-]+$"; "\(.prefix)latest") | .manifest_tag = (.image_tag | rtrimstr("-latest"))),
    (.image_tag |= sub("(?<prefix>^|-)[^-]+$"; "\(.prefix)ccache") | .manifest_tag = (.image_tag | rtrimstr("-latest")))
  ]
) | flatten
