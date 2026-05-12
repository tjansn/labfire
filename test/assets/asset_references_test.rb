require "test_helper"
require "set"

class AssetReferencesTest < ActiveSupport::TestCase
  test "static image and css asset references exist" do
    asset_paths = Dir[Rails.root.join("app/assets/images/**/*")]
      .select { |path| File.file?(path) }
      .map { |path| Pathname(path).relative_path_from(Rails.root.join("app/assets/images")).to_s }
      .to_set

    references = css_url_references + erb_asset_references
    missing = references.uniq.reject { |reference| asset_paths.include?(reference) }

    assert_empty missing.sort
  end

  private
    def css_url_references
      Dir[Rails.root.join("app/assets/stylesheets/**/*.css")].flat_map do |path|
        File.read(path).scan(/url\(([^)]+)\)/).flatten.filter_map do |reference|
          normalize_asset_reference(reference)
        end
      end
    end

    def erb_asset_references
      Dir[Rails.root.join("app/{views,helpers}/**/*.{erb,rb}")].flat_map do |path|
        File.read(path).scan(/(?:image_tag|image_url)\s*(?:\(?\s*)["']([^"']+)["']/).flatten.filter_map do |reference|
          normalize_asset_reference(reference)
        end
      end
    end

    def normalize_asset_reference(reference)
      reference = reference.strip.delete_prefix("\"").delete_prefix("'").delete_suffix("\"").delete_suffix("'")

      return if reference.include?("\#{")

      reference = reference.split("#", 2).first.split("?", 2).first

      return if reference.blank?
      return if reference.start_with?("data:", "http:", "https:", "/")

      reference
    end
end
