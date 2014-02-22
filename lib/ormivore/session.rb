module ORMivore
  class Session
    def initialize(repo_family)
      @real_repo_family = repo_family or fail
      @repo_proxy_family = Object.new.tap do |o|
        o.extend ORMivore::RepoFamily
        @real_repo_family.keys.each do |ec|
          o.add(SessionRepo.new(@real_repo_family[ec]), ec)
        end
      end
    end

    def repo(name)
      repo_proxy_family[name]
    end

    private

    attr_reader :real_repo_family, :repo_proxy_family
  end
end
