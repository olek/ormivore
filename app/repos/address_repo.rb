module App
  class AddressRepo
    include ORMivore::Repo

    self.default_entity_class = App::Address
  end
end
