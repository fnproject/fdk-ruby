RAW_VERSION=$(shell grep 'VERSION =' ./lib/fdk/version.rb | cut -d '"' -f 2)

ifeq ($(RELEASE), true)
FDK_VERSION=$(RAW_VERSION)
else
FDK_VERSION=$(RAW_VERSION).$(BLD_NUMBER)$(BLD_BRANCH_SUFFIX)
endif

.PHONY: set_fdk_version build set_image_version setup_test_image_build

set_fdk_version:
	echo "version: \"$(FDK_VERSION)\"" > $(BLD_INPUT_DIR)/buildOverrideVariables.conf
	echo "fdk_version=$(FDK_VERSION)" >> $(BLD_INPUT_DIR)/exportVariables.env

build:
	set -e
	gem install --no-document bundler rake rubocop test-unit
	gem build fdk.gemspec -o fdk-$(VERSION).gem
	gem install --development fdk-$(VERSION).gem
	rake rubocop
	rake test

set_image_version:
	echo "version: \"$(RUBY_VERSION)-$(FDK_VERSION)$(if $(VERSION_SUFFIX),-$(VERSION_SUFFIX),)\"" > $(BLD_INPUT_DIR)/buildOverrideVariables.conf

setup_test_image_build:
    # Build tag for the test image
	echo "version: \"ruby-$(RUBY_VERSION)-$(FDK_VERSION)\"" >$(BLD_INPUT_DIR)/buildOverrideVariables.conf
	echo "fdkVersion: \"$(FDK_VERSION)\"" >>$(BLD_INPUT_DIR)/buildOverrideVariables.conf
	echo "buildImageVersion: \"$(RUBY_VERSION)-$(FDK_VERSION)-dev\"" >>$(BLD_INPUT_DIR)/buildOverrideVariables.conf
	echo "runtimeImageVersion: \"$(RUBY_VERSION)-$(FDK_VERSION)\"" >>$(BLD_INPUT_DIR)/buildOverrideVariables.conf
	cat $(BLD_INPUT_DIR)/buildOverrideVariables.conf
	find $(BLD_INPUT_DIR)/internal/tests-images -name 'Gemfile' -exec sh -c 'cp "$(BLD_INPUT_DIR)/fdk-$(FDK_VERSION).gem" "$$(dirname {})"' \;