group "default" {
  targets = [
    "10_6_14_r0",
    "10_11_3_r0"
  ]
}

target "build-dockerfile" {
  dockerfile = "Dockerfile"
}

target "build-platforms" {
  platforms = ["linux/amd64", "linux/arm64"]
}

target "build-common" {
  pull = true
}

######################
# Define the variables
######################

variable "REGISTRY_CACHE" {
  default = "docker.io/nlss/mariadb-cache"
}

######################
# Define the functions
######################

# Get the arguments for the build
function "get-args" {
  params = [mariadb_version, base_alpine_version]
  result = {
    MARIADB_VERSION = mariadb_version
    BASE_ALPINE_VERSION = base_alpine_version
  }
}

# Get the cache-from configuration
function "get-cache-from" {
  params = [version]
  result = [
    "type=registry,ref=${REGISTRY_CACHE}:${sha1("${version}-${BAKE_LOCAL_PLATFORM}")}"
  ]
}

# Get the cache-to configuration
function "get-cache-to" {
  params = [version]
  result = [
    "type=registry,mode=max,ref=${REGISTRY_CACHE}:${sha1("${version}-${BAKE_LOCAL_PLATFORM}")}"
  ]
}

# Get list of image tags and registries
# Takes a version and a list of extra versions to tag
# eg. get-tags("10.11.3", ["10.11.3-r0", "10.11", "latest"])
function "get-tags" {
  params = [version, extra_versions]
  result = concat(
    [
      "docker.io/nlss/mariadb:${version}",
      "ghcr.io/n0rthernl1ghts/mariadb:${version}"
    ],
    flatten([
      for extra_version in extra_versions : [
        "docker.io/nlss/mariadb:${extra_version}",
        "ghcr.io/n0rthernl1ghts/mariadb:${extra_version}"
      ]
    ])
  )
}

##########################
# Define the build targets
##########################

target "10_6_14_r0" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("10.6.14")
  cache-to   = get-cache-to("10.6.14")
  tags       = get-tags("10.6.14", ["10.6.14-r0", "10.6", "latest"])
  args       = get-args("10.6.14-r0", "3.15")
}

target "10_11_3_r0" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("10.11.3")
  cache-to   = get-cache-to("10.11.3")
  tags       = get-tags("10.11.3", ["10.11.3-r0", "10.11", "latest"])
  args       = get-args("10.11.3-r0", "3.18.0")
}