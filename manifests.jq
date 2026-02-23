def normalize_manifest_tag:
  ltrimstr("latest-")
  | sub("^(?<prefix>.+)-(?<date>[0-9]{8})$"; "\(.date)-\(.prefix)");

.tags | map(
  {
    image_tag: split(":")[-1],
    registry: split("/")[0],
    repo: split(":")[0]
  } | [
    (.image_tag |= sub("^\($tag_prefix)"; "latest") | .manifest_tag = (.image_tag | normalize_manifest_tag)),
    (.image_tag |= sub("^\($tag_prefix)"; "ccache") | .manifest_tag = (.image_tag | normalize_manifest_tag))
  ]
) | flatten
