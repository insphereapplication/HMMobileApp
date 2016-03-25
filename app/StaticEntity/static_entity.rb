class StaticEntity
  include Rhom::FixedSchema
  property :names, :string
  property :type, :string
  
  enable :sync
  set :sync_priority, 20 # this needs to be loaded before opportunities so that opportunities can know their context
  set :schema_version, '1.0'
  
  def self.get_carrier_names
    carriers = StaticEntity.find_by_sql("select * from StaticEntity where type='carriers'").first
    carrier_names = carriers.names.split('||').sort
  end
  
  def self.get_lob_names
    lob = StaticEntity.find_by_sql("select * from StaticEntity where type='line_of_business'").first
    lob_names = lob.names.split('||')
  end

  def self.get_rawlead_lob_names
    lob = StaticEntity.find_by_sql("select * from StaticEntity where type='rawlead_lineofbusiness'").first
    lob_names = lob.names.split('||')
  end
  
  def self.get_lead_source_names
    lead_source = StaticEntity.find_by_sql("select * from StaticEntity where type='lead_source'").first
    lead_source_names = lead_source.names.split('||')
  end

  def self.reassign_flag?
    flag = StaticEntity.find_by_sql("select * from StaticEntity where type='reassign_capability'").first
    flag.names == 'true'
  end

  def self.get_agents
    agents = StaticEntity.find_by_sql("select * from StaticEntity where type='downline_source'").first
    Rho::JSON.parse(agents.names)
  end

  def self.find_agent(systemuserid)
    found_agents = get_agents.find_all {|agent| agent['systemuserid'] == systemuserid}
    (found_agents.length > 0) ? found_agents[0] : nil
  end

  def self.system_user_id
    sys_user = StaticEntity.find_by_sql("select * from StaticEntity where type='systemuserid'").first
    if sys_user.blank?
      ExceptionUtil.log_exception_to_server(Exception.new("Static entity  -- The system userid is nil.  Resetting the StaticEntity model since it should not be nil"))
      Rhom::Rhom.database_full_reset_ex(:models => ['StaticEntity'])
      Rho::RhoConnectClient.doSyncSource(StaticEntity.get_source_name, false)
    end
    sys_user.names
  end
end
