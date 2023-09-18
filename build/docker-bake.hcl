group "default" {
  targets = [
    "10_6",
    "10_11"
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
  params = [mariadb_version]
  result = {
    MARIADB_VERSION = mariadb_version
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

target "10_6" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("10.6.13")
  cache-to   = get-cache-to("10.6.13")
  tags       = get-tags("10.6", [])
  args       = get-args("10.6.13")
}

target "10_11" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("10.11.5")
  cache-to   = get-cache-to("10.11.5")
  tags       = get-tags("10.11", ["10", "latest"])
  args       = get-args("10.11.5")
}