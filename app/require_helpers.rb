module RequireHelpers
  class << self
    def root
      File.expand_path('../..', __FILE__)
    end

    def augment_load_path
      $LOAD_PATH.unshift(File.join(root, 'lib'))
      $LOAD_PATH.unshift(File.join(root, 'app'))
      $LOAD_PATH.unshift(root)
    end

    def require_independent_files_in_dir(dir)
      Dir.glob(File.join(root, dir, '*.rb')).each do |absolute_path|
        short_path = absolute_path.sub(/^#{root}\/lib\/(.*)\.rb$/, '\1')
        require short_path
      end
    end

    def require_all
      augment_load_path

      require 'init'

      require 'app/connection_manager'

      require_independent_files_in_dir 'app/models'
      require_independent_files_in_dir 'app/models/storage/ar'
    end
  end
end
