.tags | map(
  {
    "registry": split("/")[0],
    "repo": split(":")[0],
    "tag": split(":")[-1]
  }
) | map(
  [
    .tag |= sub("^\($tag_prefix)"; "tcp"),
    .tag |= sub("^\($tag_prefix)"; "ssh"),
    .tag |= sub("^\($tag_prefix)"; "tcp-ccache"),
    .tag |= sub("^\($tag_prefix)"; "ssh-ccache")
  ]
) | flatten
