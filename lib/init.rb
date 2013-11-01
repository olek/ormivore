#root = File.expand_path('..', __FILE__)
#$LOAD_PATH.unshift(File.join(root))

require 'ormivore/errors'
require 'ormivore/entity'
require 'ormivore/port'
require 'ormivore/repo'
require 'ormivore/connections'
require 'ormivore/memory_adapter'
require 'ormivore/ar_adapter'
require 'ormivore/redis_adapter'
require 'ormivore/sequel_adapter'
