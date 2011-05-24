class ClientException
  include Rhom::PropertyBag
  
  set :schema_version, '1.0'
  enable :sync
end