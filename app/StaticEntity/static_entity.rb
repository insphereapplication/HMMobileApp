class StaticEntity
  include Rhom::FixedSchema
  property :names, :string
  property :type, :string
  
  enable :sync
  set :schema_version, '1.0'
  
  def self.get_carrier_names
    carriers = StaticEntity.find_by_sql("select * from StaticEntity where type='carriers'")
    carrier_names = carriers.names.split('||').sort
  end
  
  def self.get_lob_names
    lob = StaticEntity.find_by_sql("select * from StaticEntity where type='line_of_business'")
    lob_names = lob.names.split('||')
  end

  def self.get_rawlead_lob_names
    lob = StaticEntity.find_by_sql("select * from StaticEntity where type='rawlead_lineofbusiness'")
    lob_names = lob.names.split('||')
  end
  
  def self.get_lead_source_names
    lead_source = StaticEntity.find_by_sql("select * from StaticEntity where type='lead_source'")
    lead_source_names = lead_source.names.split('||')
  end
end
