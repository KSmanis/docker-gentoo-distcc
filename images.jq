.tags | map(
  {
    image: .,
    image_tag: (split(":")[-1] | split("-")[1:] | join("-")),
    repo: split(":")[0]
  }
)
