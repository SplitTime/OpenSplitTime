module Interactors
  class CreatePeopleFromEfforts
    include Interactors::Errors

    def self.perform!(effort_ids)
      id_hash = effort_ids.zip(Array.new(effort_ids.size)).to_h
      Interactors::AssignPeopleToEfforts.perform!(id_hash)
    end
  end
end
