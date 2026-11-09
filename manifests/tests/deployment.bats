#!/usr/bin/env bats

setup() {
  cd "$BATS_TEST_DIRNAME/.."
  RENDERED="$(helm template pihole-test .)"
  export RENDERED
}

@test "pihole Deployment's pod has a pihole-exporter sidecar container" {
  name=$(echo "$RENDERED" | yq eval-all '
    select(.kind == "Deployment" and .metadata.name == "pihole") |
    .spec.template.spec.containers[1].name
  ' -)
  [ "$name" = "pihole-exporter" ]
}

@test "the pihole-exporter sidecar uses the digest-pinned exporter image" {
  image=$(echo "$RENDERED" | yq eval-all '
    select(.kind == "Deployment" and .metadata.name == "pihole") |
    (.spec.template.spec.containers[] | select(.name == "pihole-exporter") | .image)
  ' -)
  [ "$image" = "ghcr.io/mosher-labs/pihole6-exporter@sha256:aa487c8ecdb6b334ef68b1bc5fe4b95037571e7da216399d41ec1d13aff93802" ]
}

@test "the pihole-exporter sidecar is given the expected CLI args" {
  args=$(echo "$RENDERED" | yq eval-all '
    select(.kind == "Deployment" and .metadata.name == "pihole") |
    (.spec.template.spec.containers[] | select(.name == "pihole-exporter") | .args | join(" "))
  ' -)
  [ "$args" = "--host localhost --pihole-port 8080 --protocol http --port 9617" ]
}

@test "the pihole-exporter sidecar's PIHOLE_API_TOKEN matches pihole's empty webserver api password" {
  token=$(echo "$RENDERED" | yq eval-all '
    select(.kind == "Deployment" and .metadata.name == "pihole") |
    (.spec.template.spec.containers[] | select(.name == "pihole-exporter") | .env[] | select(.name == "PIHOLE_API_TOKEN") | .value)
  ' -)
  [ "$token" = "" ]
}
