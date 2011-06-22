require 'crypt/rijndael'
require 'base64'

module Crypto
  @@rijndael = Crypt::Rijndael::new( Rho::RhoConfig.crypt_key)
  
  def self.encrypt(value)
    encryptedValue = @@rijndael.encrypt_string( value )
    return encryptedValue
  end # self.encrypt
  
  def self.encryptBase64(value)
    encryptedValue = Base64.encode64(@@rijndael.encrypt_string(value))
    return encryptedValue
  end # self.encrypt
  
  def self.decrypt( value )
    decryptedValue = @@rijndael.decrypt_string( value )
    
    return decryptedValue
  end # self.decrypt
  
  def self.decryptBase64(value)
    decryptedValue = @@rijndael.decrypt_string(Base64.decode64(value))
    
    return decryptedValue
  end # self.decrypt
  
end # module Crypto