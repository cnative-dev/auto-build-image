#!/bin/bash -e

# build stage script for Auto-DevOps

if ! docker info &>/dev/null; then
  if [ -z "$DOCKER_HOST" ] && [ "$KUBERNETES_PORT" ]; then
    export DOCKER_HOST='tcp://localhost:2375'
  fi
fi

if [[ -n "$CI_REGISTRY" && -n "$CI_REGISTRY_USER" ]]; then
  echo "Logging in to GitLab Container Registry with CI credentials..."
  echo "$CI_REGISTRY_PASSWORD" | docker login -u "$CI_REGISTRY_USER" --password-stdin "$CI_REGISTRY"
fi

image_previous="$CI_APPLICATION_REPOSITORY:$CI_COMMIT_BEFORE_SHA"
image_tagged="$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG"
image_latest="$CI_APPLICATION_REPOSITORY:latest"

if [[ "$AUTO_DEVOPS_BUILD_IMAGE_CNB_ENABLED" != "false" && ! -f Dockerfile && -z "${DOCKERFILE_PATH}" ]]; then
  builder=${AUTO_DEVOPS_BUILD_IMAGE_CNB_BUILDER:-"heroku/buildpacks:18"}
  echo "Building Cloud Native Buildpack-based application with builder ${builder}..."
  buildpack_args=()
  if [[ -n "$BUILDPACK_URL" ]]; then
    buildpack_args=('--buildpack' "$BUILDPACK_URL")
  fi
  volume_args=()
  if [[ -n "$BUILDPACK_VOLUMES" ]]; then
    volume_args=('--volume' "$BUILDPACK_VOLUMES")
  fi
  env_args=()
  if [[ -n "$AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES" ]]; then
    mapfile -t env_arg_names < <(echo "$AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES" | tr ',' "\n")
    for env_arg_name in "${env_arg_names[@]}"; do
      env_args+=('--env' "$env_arg_name")
    done
  fi
  pack build tmp-cnb-image \
    --builder "$builder" \
    "${env_args[@]}" \
    "${buildpack_args[@]}" \
    "${volume_args[@]}" \
    --env HTTP_PROXY \
    --env http_proxy \
    --env HTTPS_PROXY \
    --env https_proxy \
    --env FTP_PROXY \
    --env ftp_proxy \
    --env NO_PROXY \
    --env no_proxy

  cp /build/cnb.Dockerfile Dockerfile

  docker build \
    --build-arg source_image=tmp-cnb-image \
    --tag "$image_tagged" \
    --tag "$image_latest" \
    .

  docker push "$image_tagged"
  docker push "$image_latest"
  exit 0
fi

if [[ -n "${DOCKERFILE_PATH}" ]]; then
  echo "Building Dockerfile-based application using '${DOCKERFILE_PATH}'..."
else
  export DOCKERFILE_PATH="Dockerfile"

  if [[ -f "${DOCKERFILE_PATH}" ]]; then
    echo "Building Dockerfile-based application..."
  else
    echo "Building Heroku-based application using gliderlabs/herokuish docker image..."
    erb -T - /build/Dockerfile.erb > "${DOCKERFILE_PATH}"
  fi
fi

if [[ ! -f "${DOCKERFILE_PATH}" ]]; then
  echo "Unable to find '${DOCKERFILE_PATH}'. Exiting..." >&2
  exit 1
fi

# By default we support DOCKER_BUILDKIT, however it can be turned off
# by explicitly setting this to an empty string
DOCKER_BUILDKIT=${DOCKER_BUILDKIT:-1}

# shellcheck disable=SC2206
build_args=(
  --cache-from "$image_previous"
  --cache-from "$image_latest"
  -f "$DOCKERFILE_PATH"
  --build-arg BUILDPACK_URL="$BUILDPACK_URL"
  --build-arg HTTP_PROXY="$HTTP_PROXY"
  --build-arg http_proxy="$http_proxy"
  --build-arg HTTPS_PROXY="$HTTPS_PROXY"
  --build-arg https_proxy="$https_proxy"
  --build-arg FTP_PROXY="$FTP_PROXY"
  --build-arg ftp_proxy="$ftp_proxy"
  --build-arg NO_PROXY="$NO_PROXY"
  --build-arg no_proxy="$no_proxy"
  $AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS
  --tag "$image_tagged"
  --tag "$image_latest"
)

if [[ -n "$AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES" ]]; then
  build_secret_file_path=/tmp/auto-devops-build-secrets
  "$(dirname "$0")"/export-build-secrets > "$build_secret_file_path"
  build_args+=(
    --secret "id=auto-devops-build-secrets,src=$build_secret_file_path"
  )

  # Setting build time secrets always requires buildkit
  DOCKER_BUILDKIT=1
fi

cache_type=$AUTO_DEVOPS_BUILD_CACHE
cache_mode=${AUTO_DEVOPS_BUILD_CACHE_MODE:-max}
registry_ref=${AUTO_DEVOPS_BUILD_CACHE_REF:-"${CI_APPLICATION_REPOSITORY}:cache"}

if [[ -n "$DOCKER_BUILDKIT" && "$DOCKER_BUILDKIT" != "0" ]]; then
  case "$cache_type" in
    inline)
      build_args+=(--cache-to type=inline) ;;
    registry)
      build_args+=(
        --cache-from "$registry_ref"
        --cache-to "type=registry,ref=$registry_ref,mode=$cache_mode"
      )
      ;;
  esac

  docker buildx create --use
  docker buildx build \
    "${build_args[@]}" \
    --progress=plain \
    --push \
    . 2>&1
else
  echo "Attempting to pull a previously built image for use with --cache-from..."
  docker image pull --quiet "$image_previous" || \
    docker image pull --quiet "$image_latest" || \
    echo "No previously cached image found. The docker build will proceed without using a cached image"

  docker build "${build_args[@]}" .

  docker push "$image_tagged"
  docker push "$image_latest"
fi
