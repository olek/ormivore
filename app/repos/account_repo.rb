module App
  class AccountRepo
    include ORMivore::Repo

    self.default_entity_class = App::Account
  end
end
