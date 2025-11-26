# Step 1: Package dependencies (only rebuilds when pyproject.toml changes)
resource "null_resource" "package_dependencies" {
  triggers = {
    dependencies_hash = local.dependencies_hash
    python_runtime    = var.python_runtime
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -e

      SOURCE_PATH="${var.runtime_source_path}"
      OUTPUT_DIR="${local.package_output_dir}"
      DEPS_DIR="${local.dependencies_dir}"
      PYTHON_VERSION="${lower(replace(replace(var.python_runtime, "PYTHON_", ""), "_", "."))}"

      # Convert source path to absolute
      if [ ! -d "$SOURCE_PATH" ]; then
        echo "Error: Source path does not exist: $SOURCE_PATH"
        exit 1
      fi
      SOURCE_PATH=$(cd "$SOURCE_PATH" && pwd)
      mkdir -p "$OUTPUT_DIR"
      OUTPUT_DIR=$(cd "$OUTPUT_DIR" && pwd)
      DEPS_DIR="$OUTPUT_DIR/dependencies"

      echo "=== Step 1: Installing Dependencies ==="
      echo "Source: $SOURCE_PATH"
      echo "Dependencies Dir: $DEPS_DIR"
      echo "Python Version: $PYTHON_VERSION"

      # Clean up existing dependencies
      rm -rf "$DEPS_DIR"
      mkdir -p "$DEPS_DIR"

      # Install dependencies using uv
      echo "Installing dependencies from pyproject.toml..."
      uv pip install \
        --python-platform aarch64-manylinux2014 \
        --python-version "$PYTHON_VERSION" \
        --target="$DEPS_DIR" \
        --only-binary=:all: \
        -r "$SOURCE_PATH/pyproject.toml"

      echo "=== Dependencies Installation Complete ==="
      echo "Dependencies installed to: $DEPS_DIR"
    EOT
  }
}

# Step 2: Package code (rebuilds when code changes, uses cached dependencies)
resource "null_resource" "package_code" {
  triggers = {
    code_hash              = local.code_files_hash
    dependencies_hash      = local.dependencies_hash
    agent_name             = var.agent_name
    entry_file             = var.entry_file
    additional_source_dirs = join(",", var.additional_source_dirs)
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -e

      SOURCE_PATH="${var.runtime_source_path}"
      OUTPUT_DIR="${local.package_output_dir}"
      DEPS_DIR="${local.dependencies_dir}"
      ENTRY_FILE="${var.entry_file}"
      ADDITIONAL_DIRS="${join(" ", var.additional_source_dirs)}"

      # Convert paths to absolute
      if [ ! -d "$SOURCE_PATH" ]; then
        echo "Error: Source path does not exist: $SOURCE_PATH"
        exit 1
      fi
      SOURCE_PATH=$(cd "$SOURCE_PATH" && pwd)
      OUTPUT_DIR=$(cd "$OUTPUT_DIR" && pwd)
      DEPS_DIR="$OUTPUT_DIR/dependencies"
      ZIP_PATH="$OUTPUT_DIR/deployment_package.zip"

      echo "=== Step 2: Packaging Code ==="
      echo "Source: $SOURCE_PATH"
      echo "Dependencies Dir: $DEPS_DIR"
      echo "Zip Path: $ZIP_PATH"
      echo "Entry File: $ENTRY_FILE"
      echo "Additional Dirs: $ADDITIONAL_DIRS"

      # Remove old zip
      rm -f "$ZIP_PATH"

      # Create zip from cached dependencies
      echo "Creating deployment package from cached dependencies..."
      cd "$DEPS_DIR"
      zip -rq "$ZIP_PATH" .

      # Add entry file
      echo "Adding entry file: $ENTRY_FILE"
      cd "$SOURCE_PATH"
      if [ ! -f "$ENTRY_FILE" ]; then
        echo "Error: Entry file not found: $SOURCE_PATH/$ENTRY_FILE"
        exit 1
      fi
      zip -q "$ZIP_PATH" "$ENTRY_FILE"

      # Add additional source directories (including .env files)
      for dir in $ADDITIONAL_DIRS; do
        if [ -d "$SOURCE_PATH/$dir" ]; then
          echo "Adding directory: $dir"
          cd "$SOURCE_PATH"
          # Include all files including hidden ones like .env
          zip -rq "$ZIP_PATH" "$dir" -x "*.pyc" -x "*__pycache__*"
        else
          echo "Warning: Directory $dir not found, skipping..."
        fi
      done

      echo "=== Packaging Complete ==="
      echo "Package created: $ZIP_PATH"
      ls -lh "$ZIP_PATH"
    EOT
  }

  depends_on = [null_resource.package_dependencies]
}
