require 'crypt/rijndael'
require 'base64'


class Crypto
  
  def self.get_rijndael
     # Will need to use change back to the AppInfo once the property bag is working.
     #Crypt::Rijndael::new( AppInfo.instance.mobile_crypt_key )
     Crypt::Rijndael::new( CryptKey.instance.mobile_crypt_key )
  end 

  
  def self.encrypt(value)  
    get_rijndael.encrypt_string( value )
  end # self.encrypt
  
  def self.encryptBase64(value)
    Base64.encode64(get_rijndael.encrypt_string( value ))
  end # self.encrypt
  
  def self.decrypt( value )
    get_rijndael.decrypt_string( value )
  end # self.decrypt
  
  def self.decryptBase64(value)
    get_rijndael.decrypt_string(Base64.decode64( value ))
  end # self.decrypt
  
end # module Crypto