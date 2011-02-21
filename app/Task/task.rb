class Task
  include Rhom::FixedSchema

  enable :sync

  property :activity_type, :string
  property :subject, :string
  property :follow_up_date, :string
  property :start_time, :string
  property :end_time, :string  
end
