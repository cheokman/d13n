module D13n
  module VERSION
    MAJOR     = 0
    MINOR     = 5
    TINY      = 3

    STRING = [MAJOR, MINOR, TINY].join('.')

    CODENAME = 'd13n'
  end

  NAME = 'd13n'.freeze
  RELEASE  = "#{NAME} #{VERSION::STRING} codename #{VERSION::CODENAME}".freeze
end
