class String
  # By default, +camelize+ converts strings to UpperCamelCase.
  #
  #   'active_record'.camelize                # => "ActiveRecord"
  def camelize
    string = self
    string.split('_').map{ |e| e.capitalize }.join
  end
  
  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
end