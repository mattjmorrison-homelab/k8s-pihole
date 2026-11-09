#!/usr/bin/env bats

setup() {
  cd "$BATS_TEST_DIRNAME/.."
  RENDERED="$(helm template pihole-test .)"
  export RENDERED
}

@test "the pihole Service exposes a metrics port on 9617" {
  port=$(echo "$RENDERED" | yq eval-all '
    select(.kind == "Service" and .metadata.name == "pihole") |
    (.spec.ports[] | select(.name == "metrics") | .port)
  ' -)
  [ "$port" = "9617" ]

  target_port=$(echo "$RENDERED" | yq eval-all '
    select(.kind == "Service" and .metadata.name == "pihole") |
    (.spec.ports[] | select(.name == "metrics") | .targetPort)
  ' -)
  [ "$target_port" = "9617" ]
}
