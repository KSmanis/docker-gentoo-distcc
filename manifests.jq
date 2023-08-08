.tags | map(
  {
    "registry": split("/")[0],
    "repo": split(":")[0],
    "tag": split(":")[-1] | split("-")[1:] | join("-")
  }
) | map(
  [
    .tag |= (split("-") | .[0] = "tcp" | join("-")),
    .tag |= (split("-") | .[0] = "ssh" | join("-"))
  ]
) | flatten
