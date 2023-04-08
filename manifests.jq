.tags | map(
  {
    "registry": split("/")[0],
    "repo": split(":")[0],
    "tag": split(":")[-1] | split("-")[1:] | join("-")
  }
) | map(
  [
    .,
    .tag |= (split("-") | .[0] = (if .[0] == "tcp" then "ssh" elif .[0] == "ssh" then "tcp" else .[0] end) | join("-"))
  ]
) | flatten
