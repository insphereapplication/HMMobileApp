class Note
  include Rhom::FixedSchema
  # enable :sync

  belongs_to :parent_id, ['Contact', 'Opportunity']
end
