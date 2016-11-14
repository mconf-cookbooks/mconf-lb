module MconfLB
  module Helper

    def use_systemd?
      node['platform'] == 'ubuntu' && Gem::Version.new(node['platform_version']) >= Gem::Version.new('16.04')
    end

  end
end
