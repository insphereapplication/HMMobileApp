class StaticEntity
  include Rhom::PropertyBag

  enable :sync
  set :schema_version, '1.0'
  
  def self.get_carrier_names
    carriers = StaticEntity.find('carriers')
    carrier_names = carriers.names.split('||').sort
  end
  
  def self.get_lob_names
    lob = StaticEntity.find('line_of_business')
    lob_names = lob.names.split('||')
  end

  def self.get_rawlead_lob_names
    lob = StaticEntity.find('rawlead_lineofbusiness')
    lob_names = lob.names.split('||')
  end
  
  def self.get_lead_source_names
    lead_source = StaticEntity.find('lead_source')
    lead_source_names = lead_source.names.split('||')
  end
end
