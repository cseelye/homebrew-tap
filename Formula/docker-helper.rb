class DockerHelper < Formula
  desc "Docker CLI plugins for cleanup, IP lookup, and resource queries"
  homepage "https://github.com/cseelye/docker-helper"
  url "https://github.com/cseelye/docker-helper/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "4e6909125b3d3056b46d942382caa0e2be5adc36483779eb2e087e7cab1b6921"
  license "MIT"

  option "with-system-links", "Link plugins into /usr/local/lib/docker/cli-plugins using sudo"

  depends_on "python@3.14"

  def install
    libexec.install "docker-cleanup", "docker-ip", "docker-query",
                    "docker-helper-link", "plugins.txt"
    (bin/"docker-helper-link").write <<~SH
      #!/bin/bash
      exec "#{opt_libexec}/docker-helper-link" --source "#{opt_libexec}" "$@"
    SH
  end

  def post_install
    return if build.without? "system-links"

    system bin/"docker-helper-link", "--system"
  end

  def caveats
    <<~EOS
      Link the helpers into ${DOCKER_CONFIG:-$HOME/.docker}/cli-plugins with:
        docker-helper-link

      To link into /usr/local/lib/docker/cli-plugins during installation and
      allow docker-helper-link to prompt for sudo, install with:
        brew install cseelye/tap/docker-helper --with-system-links

      Before uninstalling, remove only Docker-helper-owned links with:
        docker-helper-link --remove

      For a system-link installation, remove them with:
        docker-helper-link --system --remove
    EOS
  end

  test do
    metadata = shell_output("#{libexec}/docker-cleanup docker-cli-plugin-metadata")
    assert_match '"SchemaVersion": "0.1.0"', metadata

    plugin_dir = testpath/"cli-plugins"
    system bin/"docker-helper-link", "--plugin-dir", plugin_dir

    %w[docker-cleanup docker-ip docker-query].each do |plugin|
      link = plugin_dir/plugin
      assert_predicate link, :symlink?
      assert_equal (opt_libexec/plugin).to_s, link.readlink.to_s
    end
  end
end
