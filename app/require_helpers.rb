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

      require 'ormivore'

      require 'ormivore/ar_adapter'
      require 'ormivore/redis_adapter'
      require 'ormivore/sequel_adapter'
      require 'ormivore/prepared_sequel_adapter'

      require 'app/connection_manager'

      require_independent_files_in_dir 'app/converters'
      require_independent_files_in_dir 'app/adapters'
      require_independent_files_in_dir 'app/ports'
      require_independent_files_in_dir 'app/entities'
      require_independent_files_in_dir 'app/repos'
    end
  end
end
